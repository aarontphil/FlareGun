import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/identity.dart';
import '../ai/offline_ai.dart';
import 'nearby_service.dart';

class MeshProvider extends ChangeNotifier {
  late DeviceIdentity _identity;
  DeviceIdentity get identity => _identity;

  final NearbyService nearby = NearbyService();
  bool _nearbyActive = false;
  bool get nearbyActive => _nearbyActive;

  WebSocketChannel? _channel;
  bool _wsConnected = false;
  bool get wsConnected => _wsConnected;
  String _serverUrl = '';
  String get serverUrl => _serverUrl;
  Timer? _reconnectTimer;

  final Map<String, Peer> _peers = {};
  List<Peer> get peers => _peers.values.toList();
  List<Peer> get connectedPeers => peers.where((p) => p.connected).toList();
  int get peerCount => connectedPeers.length;

  final Map<String, List<MeshMessage>> _conversations = {};
  final List<MeshMessage> _broadcastMessages = [];
  List<MeshMessage> get broadcastMessages => List.unmodifiable(_broadcastMessages);

  final LinkedHashSet<String> _seenMessageIds = LinkedHashSet();
  static const int _maxSeenSize = 500;

  List<MeshMessage> getConversation(String peerId) {
    return List.unmodifiable(_conversations[peerId] ?? []);
  }

  MeshMessage? lastMessage(String peerId) {
    final conv = _conversations[peerId];
    if (conv == null || conv.isEmpty) return null;
    return conv.last;
  }

  int unreadCount(String peerId) {
    return _conversations[peerId]
        ?.where((m) => m.senderId != _identity.id && !(m.aiAnalysis?['read'] == true))
        .length ?? 0;
  }

  late Box _identityBox;
  late Box _messagesBox;
  late Box _settingsBox;

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

  Future<bool> startNearby() async {
    _nearbyActive = await nearby.start(_identity.name);
    notifyListeners();
    return _nearbyActive;
  }

  Future<void> stopNearby() async {
    await nearby.stop();
    _nearbyActive = false;
    _peers.clear();
    notifyListeners();
  }

  Future<void> connectToPeer(String endpointId) async {
    await nearby.connectTo(endpointId);
  }

  bool _hasSeen(String msgId) {
    return _seenMessageIds.contains(msgId);
  }

  void _markSeen(String msgId) {
    _seenMessageIds.add(msgId);
    while (_seenMessageIds.length > _maxSeenSize) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
  }

  void _handleNearbyMessage(String endpointId, String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final msg = MeshMessage.fromJson(data);

      if (_hasSeen(msg.id)) return;
      _markSeen(msg.id);

      if (msg.senderId == _identity.id) return;

      _conversations.putIfAbsent(endpointId, () => []);
      if (!_conversations[endpointId]!.any((m) => m.id == msg.id)) {
        _conversations[endpointId]!.add(msg);
        _conversations[endpointId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _persistMessage(endpointId, msg);
      }

      if (!_broadcastMessages.any((m) => m.id == msg.id)) {
        _broadcastMessages.add(msg);
        _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      if (msg.canForward) {
        _forwardToOthers(endpointId, msg);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Parse error: $e');
    }
  }

  void _forwardToOthers(String sourceEndpointId, MeshMessage msg) {
    final forwarded = msg.forwarded();
    final payload = jsonEncode(forwarded.toJson());

    for (final peerId in nearby.connectedEndpoints.keys) {
      if (peerId == sourceEndpointId) continue;
      nearby.sendMessage(peerId, payload);
    }
  }

  Future<void> sendMessageTo(String peerId, String text, {String priority = 'normal'}) async {
    if (text.trim().isEmpty) return;

    final msg = MeshMessage(
      text: text.trim(),
      senderId: _identity.id,
      senderName: _identity.name,
      priority: priority,
    );

    _markSeen(msg.id);

    _conversations.putIfAbsent(peerId, () => []);
    _conversations[peerId]!.add(msg);
    await _persistMessage(peerId, msg);
    notifyListeners();

    if (nearby.connectedEndpoints.containsKey(peerId)) {
      await nearby.sendMessage(peerId, jsonEncode(msg.toJson()));
    }

    for (final otherId in nearby.connectedEndpoints.keys) {
      if (otherId == peerId) continue;
      await nearby.sendMessage(otherId, jsonEncode(msg.toJson()));
    }

    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
    }
  }

  Future<void> broadcastMsg(String text, {String priority = 'normal'}) async {
    if (text.trim().isEmpty) return;

    final msg = MeshMessage(
      text: text.trim(),
      senderId: _identity.id,
      senderName: _identity.name,
      priority: priority,
    );

    _markSeen(msg.id);
    _broadcastMessages.add(msg);
    notifyListeners();

    await nearby.broadcastMessage(jsonEncode(msg.toJson()));

    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
    }
  }

  String aiChat(String query) {
    return OfflineAI.chat(query);
  }

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
        onDone: () { _wsConnected = false; notifyListeners(); _scheduleReconnect(); },
        onError: (_) { _wsConnected = false; notifyListeners(); _scheduleReconnect(); },
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
          if (!_hasSeen(msg.id)) {
            _markSeen(msg.id);
            if (!_broadcastMessages.any((m) => m.id == msg.id)) {
              _broadcastMessages.add(msg);
              _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
              notifyListeners();
            }
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

  Future<void> setDeviceName(String name) async {
    _identity.name = name;
    await _identityBox.put('device', _identity.toJson());
    notifyListeners();
  }

  void _loadMessages() {
    for (final key in _messagesBox.keys) {
      try {
        final raw = _messagesBox.get(key);
        if (raw is Map) {
          final data = Map<String, dynamic>.from(raw);
          final peerId = data['_peerId'] as String? ?? '_broadcast';
          final msg = MeshMessage.fromJson(data);
          _markSeen(msg.id);
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
    _seenMessageIds.clear();
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
