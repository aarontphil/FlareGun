import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';

/// Callback types for nearby events.
typedef PeerCallback = void Function(String endpointId, String name);
typedef MessageCallback = void Function(String endpointId, String message);
typedef StatusCallback = void Function(bool active);

/// Wraps Google Nearby Connections API for true offline P2P.
/// Works over Bluetooth + WiFi Direct — no internet needed.
class NearbyService {
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  String _userName = 'MeshUser';
  String _serviceId = 'com.meshlink.mesh';

  final Map<String, String> connectedEndpoints = {}; // id -> name
  final Map<String, String> discoveredEndpoints = {}; // id -> name

  bool isAdvertising = false;
  bool isDiscovering = false;

  // Callbacks
  PeerCallback? onPeerFound;
  PeerCallback? onPeerLost;
  PeerCallback? onPeerConnected;
  PeerCallback? onPeerDisconnected;
  MessageCallback? onMessageReceived;
  StatusCallback? onAdvertisingStatus;
  StatusCallback? onDiscoveryStatus;

  final Nearby _nearby = Nearby();

  /// Start advertising + discovering simultaneously.
  Future<bool> start(String userName) async {
    _userName = userName;
    final adv = await startAdvertising();
    final disc = await startDiscovery();
    return adv || disc;
  }

  /// Stop everything.
  Future<void> stop() async {
    await stopAdvertising();
    await stopDiscovery();
    await _nearby.stopAllEndpoints();
    connectedEndpoints.clear();
    discoveredEndpoints.clear();
  }

  /// Make this device discoverable.
  Future<bool> startAdvertising() async {
    try {
      final result = await _nearby.startAdvertising(
        _userName,
        _strategy,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      isAdvertising = result;
      onAdvertisingStatus?.call(result);
      debugPrint('[Nearby] Advertising: $result');
      return result;
    } catch (e) {
      debugPrint('[Nearby] Advertising error: $e');
      return false;
    }
  }

  Future<void> stopAdvertising() async {
    await _nearby.stopAdvertising();
    isAdvertising = false;
    onAdvertisingStatus?.call(false);
  }

  /// Scan for nearby devices.
  Future<bool> startDiscovery() async {
    try {
      final result = await _nearby.startDiscovery(
        _userName,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          debugPrint('[Nearby] Found: $name ($id)');
          discoveredEndpoints[id] = name;
          onPeerFound?.call(id, name);
        },
        onEndpointLost: (id) {
          if (id == null) return;
          debugPrint('[Nearby] Lost: $id');
          final name = discoveredEndpoints.remove(id) ?? 'Unknown';
          onPeerLost?.call(id, name);
        },
        serviceId: _serviceId,
      );
      isDiscovering = result;
      onDiscoveryStatus?.call(result);
      debugPrint('[Nearby] Discovery: $result');
      return result;
    } catch (e) {
      debugPrint('[Nearby] Discovery error: $e');
      return false;
    }
  }

  Future<void> stopDiscovery() async {
    await _nearby.stopDiscovery();
    isDiscovering = false;
    onDiscoveryStatus?.call(false);
  }

  /// Connect to a discovered peer.
  Future<void> connectTo(String endpointId) async {
    try {
      await _nearby.requestConnection(
        _userName,
        endpointId,
        onConnectionInitiated: _onConnectionInit,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      debugPrint('[Nearby] Connect error: $e');
    }
  }

  /// Disconnect from a peer.
  Future<void> disconnectFrom(String endpointId) async {
    await _nearby.disconnectFromEndpoint(endpointId);
    final name = connectedEndpoints.remove(endpointId);
    onPeerDisconnected?.call(endpointId, name ?? 'Unknown');
  }

  /// Send a text message to a specific peer.
  Future<void> sendMessage(String endpointId, String message) async {
    try {
      await _nearby.sendBytesPayload(
        endpointId,
        Uint8List.fromList(utf8.encode(message)),
      );
    } catch (e) {
      debugPrint('[Nearby] Send error: $e');
    }
  }

  /// Broadcast a message to all connected peers.
  Future<void> broadcastMessage(String message) async {
    final bytes = Uint8List.fromList(utf8.encode(message));
    for (final id in connectedEndpoints.keys) {
      try {
        await _nearby.sendBytesPayload(id, bytes);
      } catch (e) {
        debugPrint('[Nearby] Broadcast to $id failed: $e');
      }
    }
  }

  // ── Connection callbacks ──

  void _onConnectionInit(String id, ConnectionInfo info) {
    debugPrint('[Nearby] Connection init: ${info.endpointName} ($id)');
    // Auto-accept all connections
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final message = utf8.decode(payload.bytes!);
          debugPrint('[Nearby] Received from $endpointId: ${message.substring(0, message.length.clamp(0, 50))}');
          onMessageReceived?.call(endpointId, message);
        }
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      final name = discoveredEndpoints[id] ?? 'Unknown';
      connectedEndpoints[id] = name;
      debugPrint('[Nearby] Connected: $name ($id)');
      onPeerConnected?.call(id, name);
    } else {
      debugPrint('[Nearby] Connection failed: $id ($status)');
    }
  }

  void _onDisconnected(String id) {
    final name = connectedEndpoints.remove(id);
    debugPrint('[Nearby] Disconnected: $name ($id)');
    onPeerDisconnected?.call(id, name ?? 'Unknown');
  }

  int get connectedCount => connectedEndpoints.length;
  int get discoveredCount => discoveredEndpoints.length;
}
