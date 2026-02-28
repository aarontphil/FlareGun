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

  final Map<String, String> _endpointToDevice = {};

  void _setupNearbyCallbacks() {
    nearby.onPeerFound = (endpointId, nameInfo) {
      final parts = nameInfo.split('|');
      final deviceId = parts.length > 1 ? parts[0] : endpointId;
      final name = parts.length > 1 ? parts.sublist(1).join('|') : nameInfo;

      _endpointToDevice[endpointId] = deviceId;
      _peers[deviceId] = Peer(deviceId: deviceId, name: name, connected: false);
      notifyListeners();
    };
    nearby.onPeerLost = (endpointId, _) {
      final deviceId = _endpointToDevice[endpointId];
      if (deviceId != null && _peers.containsKey(deviceId)) {
        _peers.remove(deviceId);
      }
      notifyListeners();
    };
    nearby.onPeerConnected = (endpointId, nameInfo) {
      final parts = nameInfo.split('|');
      final deviceId = parts.length > 1 ? parts[0] : endpointId;
      final name = parts.length > 1 ? parts.sublist(1).join('|') : nameInfo;

      _endpointToDevice[endpointId] = deviceId;
      _peers[deviceId] = Peer(deviceId: deviceId, name: name, connected: true);
      if (!_conversations.containsKey(deviceId)) {
        _conversations[deviceId] = [];
      }
      notifyListeners();
    };
    nearby.onPeerDisconnected = (endpointId, _) {
      final deviceId = _endpointToDevice[endpointId];
      if (deviceId != null && _peers.containsKey(deviceId)) {
        _peers[deviceId] = _peers[deviceId]!.copyWith(connected: false);
      }
      notifyListeners();
    };
    nearby.onMessageReceived = (endpointId, raw) {
      _handleNearbyMessage(endpointId, raw);
    };
  }

  Future<bool> startNearby() async {
    _nearbyActive = await nearby.start(_identity.name, _identity.id);
    notifyListeners();
    return _nearbyActive;
  }

  Future<void> stopNearby() async {
    await nearby.stop();
    _nearbyActive = false;
    _peers.clear();
    notifyListeners();
  }

  Future<void> connectToPeer(String deviceId) async {
    final entries = _endpointToDevice.entries.where((e) => e.value == deviceId).toList();
    if (entries.isNotEmpty) {
      await nearby.connectTo(entries.first.key);
    } else {
      debugPrint('[Mesh] Cannot connect: no endpoint found for device $deviceId');
    }
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

      if (msg.isReceipt) {
        _handleReceipt(msg, endpointId);
        return;
      }

      final conversationKey = msg.senderId;

      if (!_peers.containsKey(conversationKey)) {
        _peers[conversationKey] = Peer(
          deviceId: conversationKey,
          name: msg.senderName,
          connected: true,
        );
      }

      msg.status = MessageStatus.delivered;

      _conversations.putIfAbsent(conversationKey, () => []);
      if (!_conversations[conversationKey]!.any((m) => m.id == msg.id)) {
        _conversations[conversationKey]!.add(msg);
        _conversations[conversationKey]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _persistMessage(conversationKey, msg);
      }

      if (!_broadcastMessages.any((m) => m.id == msg.id)) {
        _broadcastMessages.add(msg);
        _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      _sendReceipt(msg.id, endpointId);

      if (msg.canForward) {
        _forwardToOthers(endpointId, msg);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Parse error: $e');
    }
  }

  void _handleReceipt(MeshMessage receipt, String endpointId) {
    final originalMsgId = receipt.text;

    for (final conv in _conversations.values) {
      for (final msg in conv) {
        if (msg.id == originalMsgId && msg.senderId == _identity.id) {
          msg.status = MessageStatus.delivered;
          _persistMessage(_getConversationKeyForMsg(msg), msg);
          notifyListeners();
          break;
        }
      }
    }

    if (receipt.canForward) {
      _forwardToOthers(endpointId, receipt);
    }
  }

  String _getConversationKeyForMsg(MeshMessage msg) {
    for (final entry in _conversations.entries) {
      if (entry.value.any((m) => m.id == msg.id)) {
        return entry.key;
      }
    }
    return msg.senderId;
  }

  void _sendReceipt(String originalMsgId, String endpointId) {
    final receipt = MeshMessage.receipt(originalMsgId, _identity.id, _identity.name);
    _markSeen(receipt.id);
    final payload = jsonEncode(receipt.toJson());

    for (final peerId in nearby.connectedEndpoints.keys) {
      nearby.sendMessage(peerId, payload);
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
      status: MessageStatus.sending,
    );

    _markSeen(msg.id);

    _conversations.putIfAbsent(peerId, () => []);
    _conversations[peerId]!.add(msg);
    await _persistMessage(peerId, msg);
    notifyListeners();

    final payload = jsonEncode(msg.toJson());
    bool dispatched = false;

    if (nearby.connectedEndpoints.containsKey(peerId)) {
      await nearby.sendMessage(peerId, payload);
      dispatched = true;
    }

    for (final otherId in nearby.connectedEndpoints.keys) {
      if (otherId == peerId) continue;
      await nearby.sendMessage(otherId, payload);
      dispatched = true;
    }

    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
      dispatched = true;
    }

    if (dispatched) {
      msg.status = MessageStatus.sent;
      await _persistMessage(peerId, msg);
      notifyListeners();
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
