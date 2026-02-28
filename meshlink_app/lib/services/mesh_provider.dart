import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/identity.dart';
import '../ai/offline_ai.dart';
import '../ai/gemma_service.dart';
import 'nearby_service.dart';

class MeshProvider extends ChangeNotifier {
  late DeviceIdentity _identity;
  DeviceIdentity get identity => _identity;

  final NearbyService nearby = NearbyService();
  final GemmaService gemma = GemmaService();
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

  final Map<String, String> _endpointToDevice = {};
  final Map<String, String> _deviceToEndpoint = {};

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
        ?.where((m) => m.senderId != _identity.id && !m.isRead)
        .length ?? 0;
  }

  void markConversationRead(String peerId) {
    final conv = _conversations[peerId];
    if (conv == null) return;
    bool changed = false;
    for (final msg in conv) {
      if (msg.senderId != _identity.id && !msg.isRead) {
        msg.isRead = true;
        changed = true;
      }
    }
    if (changed) {
      _persistAll();
      notifyListeners();
    }
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
    await gemma.init();
    gemma.onStatusChanged.listen((_) => notifyListeners());
    notifyListeners();
  }

  void _mapEndpoint(String endpointId, String deviceId) {
    _endpointToDevice[endpointId] = deviceId;
    _deviceToEndpoint[deviceId] = endpointId;
  }

  (String deviceId, String displayName) _parseNameInfo(String nameInfo, String fallbackId) {
    final pipe = nameInfo.indexOf('|');
    if (pipe > 0) {
      return (nameInfo.substring(0, pipe), nameInfo.substring(pipe + 1));
    }
    return (fallbackId, nameInfo);
  }

  void _setupNearbyCallbacks() {
    nearby.onPeerFound = (endpointId, nameInfo) {
      final (deviceId, name) = _parseNameInfo(nameInfo, endpointId);
      if (deviceId == _identity.id) return;
      _mapEndpoint(endpointId, deviceId);
      _peers[deviceId] = Peer(deviceId: deviceId, name: name, connected: false);
      notifyListeners();
    };

    nearby.onPeerLost = (endpointId, _) {
      final deviceId = _endpointToDevice.remove(endpointId);
      if (deviceId != null) {
        _deviceToEndpoint.remove(deviceId);
        if (_peers.containsKey(deviceId) && !_peers[deviceId]!.connected) {
          _peers.remove(deviceId);
        }
      }
      notifyListeners();
    };

    nearby.onPeerConnected = (endpointId, nameInfo) {
      final (deviceId, name) = _parseNameInfo(nameInfo, endpointId);
      if (deviceId == _identity.id) return;
      _mapEndpoint(endpointId, deviceId);
      _peers[deviceId] = Peer(deviceId: deviceId, name: name, connected: true);
      _conversations.putIfAbsent(deviceId, () => []);
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
      _handleIncoming(endpointId, raw);
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
    _endpointToDevice.clear();
    _deviceToEndpoint.clear();
    notifyListeners();
  }

  Future<void> connectToPeer(String deviceId) async {
    final endpointId = _deviceToEndpoint[deviceId];
    if (endpointId != null) {
      await nearby.connectTo(endpointId);
    }
  }

  bool _hasSeen(String msgId) => _seenMessageIds.contains(msgId);

  void _markSeen(String msgId) {
    _seenMessageIds.add(msgId);
    while (_seenMessageIds.length > _maxSeenSize) {
      _seenMessageIds.remove(_seenMessageIds.first);
    }
  }

  void _handleIncoming(String endpointId, String raw) {
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

      final senderId = msg.senderId;

      if (!_peers.containsKey(senderId)) {
        _peers[senderId] = Peer(
          deviceId: senderId,
          name: msg.senderName,
          connected: true,
        );
      }

      msg.status = MessageStatus.delivered;

      _conversations.putIfAbsent(senderId, () => []);
      if (!_conversations[senderId]!.any((m) => m.id == msg.id)) {
        _conversations[senderId]!.add(msg);
        _conversations[senderId]!.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _persistMessage(senderId, msg);
      }

      if (!_broadcastMessages.any((m) => m.id == msg.id)) {
        _broadcastMessages.add(msg);
        _broadcastMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      _sendReceipt(msg.id);

      if (msg.canForward) {
        _relayToOthers(endpointId, msg);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[Mesh] Parse error: $e');
    }
  }

  void _handleReceipt(MeshMessage receipt, String fromEndpoint) {
    final originalId = receipt.text;
    bool found = false;

    for (final conv in _conversations.values) {
      for (final msg in conv) {
        if (msg.id == originalId && msg.senderId == _identity.id) {
          msg.status = MessageStatus.delivered;
          found = true;
          break;
        }
      }
      if (found) break;
    }

    if (found) {
      _persistAll();
      notifyListeners();
    }

    if (receipt.canForward) {
      _relayToOthers(fromEndpoint, receipt);
    }
  }

  void _sendReceipt(String originalMsgId) {
    final receipt = MeshMessage.receipt(originalMsgId, _identity.id, _identity.name);
    _markSeen(receipt.id);
    final payload = jsonEncode(receipt.toJson());
    for (final eid in nearby.connectedEndpoints.keys) {
      nearby.sendMessage(eid, payload);
    }
  }

  void _relayToOthers(String sourceEndpoint, MeshMessage msg) {
    final forwarded = msg.forwarded();
    final payload = jsonEncode(forwarded.toJson());
    for (final eid in nearby.connectedEndpoints.keys) {
      if (eid == sourceEndpoint) continue;
      nearby.sendMessage(eid, payload);
    }
  }

  Future<void> _sendViaAllEndpoints(String payload) async {
    for (final eid in nearby.connectedEndpoints.keys) {
      await nearby.sendMessage(eid, payload);
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

    if (nearby.connectedEndpoints.isNotEmpty) {
      await _sendViaAllEndpoints(payload);
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
      status: MessageStatus.sending,
    );

    _markSeen(msg.id);
    _broadcastMessages.add(msg);
    notifyListeners();

    final payload = jsonEncode(msg.toJson());
    bool dispatched = false;

    if (nearby.connectedEndpoints.isNotEmpty) {
      await _sendViaAllEndpoints(payload);
      dispatched = true;
    }

    if (_wsConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'message', 'message': msg.toJson()}));
      dispatched = true;
    }

    if (dispatched) {
      msg.status = MessageStatus.sent;
      notifyListeners();
    }
  }

  String aiChat(String query) => OfflineAI.chat(query);

  Stream<String> aiChatStream(String query) async* {
    if (gemma.isReady) {
      yield* gemma.chatStream(query);
    } else {
      final response = OfflineAI.chat(query);
      yield response;
    }
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

  Future<void> _persistAll() async {
    for (final entry in _conversations.entries) {
      for (final msg in entry.value) {
        if (msg.senderId == _identity.id) {
          await _persistMessage(entry.key, msg);
        }
      }
    }
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
