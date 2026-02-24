import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/identity.dart';
import 'nearby_service.dart';

/// Central state manager — offline-first via Nearby Connections,
/// with optional WebSocket relay for server AI features.
class MeshProvider extends ChangeNotifier {
  // ── Identity ──
  late DeviceIdentity _identity;
  DeviceIdentity get identity => _identity;

  // ── Nearby (offline P2P) ──
  final NearbyService nearby = NearbyService();
  bool _nearbyActive = false;
  bool get nearbyActive => _nearbyActive;

  // ── WebSocket (optional relay) ──
  WebSocketChannel? _channel;
  bool _wsConnected = false;
  bool get wsConnected => _wsConnected;
  String _serverUrl = '';
  String get serverUrl => _serverUrl;
  Timer? _reconnectTimer;

  // ── Peers ──
  final Map<String, Peer> _peers = {};
  List<Peer> get peers => _peers.values.toList();
  List<Peer> get connectedPeers => peers.where((p) => p.connected).toList();
  int get peerCount => connectedPeers.length;

  // ── Messages (per-peer conversations) ──
  final Map<String, List<MeshMessage>> _conversations = {}; // peerId -> msgs
  final List<MeshMessage> _broadcastMessages = []; // broadcast/mesh chat
  List<MeshMessage> get broadcastMessages => List.unmodifiable(_broadcastMessages);

  List<MeshMessage> getConversation(String peerId) {
    return List.unmodifiable(_conversations[peerId] ?? []);
  }

  /// Get last message for a peer (for chat list preview).
  MeshMessage? lastMessage(String peerId) {
    final conv = _conversations[peerId];
    if (conv == null || conv.isEmpty) return null;
    return conv.last;
  }

  /// Get unread count for a peer.
  int unreadCount(String peerId) {
    return _conversations[peerId]
        ?.where((m) => m.senderId != _identity.id && !(m.aiAnalysis?['read'] == true))
        .length ?? 0;
  }

  // ── Hive ──
  late Box _identityBox;
  late Box _messagesBox;
  late Box _settingsBox;

  // ── Init ──
  Future<void> init() async {
    await Hive.initFlutter();
    _identityBox = await Hive.openBox('identity');
    _messagesBox = await Hive.openBox('messages');
    _settingsBox = await Hive.openBox('settings');

    final stored = _identityBox.get('device');
    if (stored != null) {
      _identity = DeviceIdentity.fromJson(Map<String, dynamic>.from(stored));
    } else {
      _identity = DeviceIdentity();
      await _identityBox.put('device', _identity.toJson());
    }

    _serverUrl = _settingsBox.get('serverUrl', defaultValue: '');
    _loadMessages();
    _setupNearbyCallbacks();

    notifyListeners();
  }

  // ── Nearby Connections ──

  void _setupNearbyCallbacks() {
    nearby.onPeerFound = (id, name) {
      _peers[id] = Peer(deviceId: id, name: name, connected: false);
      notifyListeners();
    };
    nearby.onPeerLost = (id, _) {
      _peers.remove(id);
      notifyListeners();
    };
    nearby.onPeerConnected = (id, name) {
      _peers[id] = Peer(deviceId: id, name: name, connected: true);
      if (!_conversations.containsKey(id)) {
        _conversations[id] = [];
      }
      notifyListeners();
    };
    nearby.onPeerDisconnected = (id, _) {
      if (_peers.containsKey(id)) {
        _peers[id] = _peers[id]!.copyWith(connected: false);
      }
      notifyListeners();
    };
    nearby.onMessageReceived = (endpointId, raw) {
      _handleNearbyMessage(endpointId, raw);
    };
  }

  /// Start offline P2P (advertise + discover).
  Future<bool> startNearby() async {
    _nearbyActive = await nearby.start(_identity.name);
    notifyListeners();
    return _nearbyActive;
  }

  /// Stop offline P2P.
  Future<void> stopNearby() async {
    await nearby.stop();
    _nearbyActive = false;
    _peers.clear();
    notifyListeners();
  }

  /// Connect to a discovered peer.
  Future<void> connectToPeer(String endpointId) async {
    await nearby.connectTo(endpointId);
  }

  void _handleNearbyMessage(String endpointId, String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final msg = MeshMessage.fromJson(data);

      // Add to conversation
      _conversations.putIfAbsent(endpointId, () => []);
      if (!_conversations[endpointId]!.any((m) => m.id == msg.id)) {
        _conversations[endpointId]!.add(msg);
        _conversations[endpointId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _persistMessage(endpointId, msg);
      }

      // Also add to broadcast if it was broadcast
      if (!_broadcastMessages.any((m) => m.id == msg.id)) {
        _broadcastMessages.add(msg);
        _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Parse error: $e');
    }
  }

  // ── Send Messages ──

  /// Send to a specific peer.
  Future<void> sendMessageTo(String peerId, String text, {String priority = 'normal'}) async {
    if (text.trim().isEmpty) return;

    final msg = MeshMessage(
      text: text.trim(),
      senderId: _identity.id,
      senderName: _identity.name,
      senderEmoji: _identity.emoji,
      priority: priority,
    );

    _conversations.putIfAbsent(peerId, () => []);
    _conversations[peerId]!.add(msg);
    await _persistMessage(peerId, msg);
    notifyListeners();

    // Send via Nearby
    if (nearby.connectedEndpoints.containsKey(peerId)) {
      await nearby.sendMessage(peerId, jsonEncode(msg.toJson()));
    }

    // Also relay via WS if connected
    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
    }
  }

  /// Broadcast to all peers.
  Future<void> broadcastMsg(String text, {String priority = 'normal'}) async {
    if (text.trim().isEmpty) return;

    final msg = MeshMessage(
      text: text.trim(),
      senderId: _identity.id,
      senderName: _identity.name,
      senderEmoji: _identity.emoji,
      priority: priority,
    );

    _broadcastMessages.add(msg);
    notifyListeners();

    await nearby.broadcastMessage(jsonEncode(msg.toJson()));

    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
    }
  }

  // ── WebSocket (optional) ──

  Future<void> connectRelay(String serverHost) async {
    _serverUrl = serverHost.replaceAll(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/$'), '');
    await _settingsBox.put('serverUrl', _serverUrl);
    _doWsConnect();
  }

  void _doWsConnect() {
    if (_serverUrl.isEmpty) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://$_serverUrl/ws'));
      _channel!.stream.listen(
        (raw) => _handleWsMessage(raw as String),
        onDone: () {
          _wsConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
        onError: (_) {
          _wsConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
      );
      _wsConnected = true;
      _channel!.sink.add(jsonEncode({'type': 'join', 'identity': _identity.toJson()}));
      notifyListeners();
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _doWsConnect);
  }

  void _handleWsMessage(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      switch (data['type']) {
        case 'peers':
          for (final p in (data['peers'] as List? ?? [])) {
            final peer = Peer.fromJson(Map<String, dynamic>.from(p));
            if (peer.deviceId != _identity.id) {
              _peers[peer.deviceId] = peer.copyWith(connected: true);
            }
          }
          notifyListeners();
          break;
        case 'peer_joined':
          final p = Peer.fromJson(Map<String, dynamic>.from(data['peer']));
          if (p.deviceId != _identity.id) {
            _peers[p.deviceId] = p.copyWith(connected: true);
            notifyListeners();
          }
          break;
        case 'peer_left':
          _peers.remove(data['peer']?['deviceId']);
          notifyListeners();
          break;
        case 'message':
          final msg = MeshMessage.fromJson(Map<String, dynamic>.from(data['message']));
          if (!_broadcastMessages.any((m) => m.id == msg.id)) {
            _broadcastMessages.add(msg);
            _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            notifyListeners();
          }
          break;
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void disconnectRelay() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _wsConnected = false;
    notifyListeners();
  }

  // ── AI (optional, server-side) ──

  Future<Map<String, dynamic>?> aiChat(String query) async {
    if (_serverUrl.isEmpty) return null;
    try {
      final res = await http.post(
        Uri.parse('http://$_serverUrl/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return null;
  }

  // ── Identity ──

  Future<void> setDeviceName(String name) async {
    _identity.name = name;
    await _identityBox.put('device', _identity.toJson());
    notifyListeners();
  }

  Future<void> setDeviceEmoji(String emoji) async {
    _identity.emoji = emoji;
    await _identityBox.put('device', _identity.toJson());
    notifyListeners();
  }

  // ── Persistence ──

  void _loadMessages() {
    for (final key in _messagesBox.keys) {
      try {
        final raw = _messagesBox.get(key);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          final peerId = data['_peerId'] as String? ?? '_broadcast';
          final msg = MeshMessage.fromJson(data);
          if (peerId == '_broadcast') {
            _broadcastMessages.add(msg);
          } else {
            _conversations.putIfAbsent(peerId, () => []);
            _conversations[peerId]!.add(msg);
          }
        }
      } catch (_) {}
    }
    _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (final conv in _conversations.values) {
      conv.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
  }

  Future<void> _persistMessage(String peerId, MeshMessage msg) async {
    final data = msg.toJson();
    data['_peerId'] = peerId;
    await _messagesBox.put(msg.id, data);
  }

  Future<void> clearData() async {
    _broadcastMessages.clear();
    _conversations.clear();
    await _messagesBox.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    nearby.stop();
    disconnectRelay();
    super.dispose();
  }
}
