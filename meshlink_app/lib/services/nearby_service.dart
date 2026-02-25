import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

typedef PeerCallback = void Function(String endpointId, String name);
typedef MessageCallback = void Function(String endpointId, String message);
typedef StatusCallback = void Function(bool active);

class NearbyService {
  static const Strategy _strategy = Strategy.P2P_CLUSTER;
  String _userName = 'User';
  final String _serviceId = 'com.meshlink.mesh';
  final Map<String, String> connectedEndpoints = {};
  final Map<String, String> discoveredEndpoints = {};
  bool isAdvertising = false;
  bool isDiscovering = false;

  PeerCallback? onPeerFound;
  PeerCallback? onPeerLost;
  PeerCallback? onPeerConnected;
  PeerCallback? onPeerDisconnected;
  MessageCallback? onMessageReceived;
  StatusCallback? onAdvertisingStatus;
  StatusCallback? onDiscoveryStatus;

  final Nearby _nearby = Nearby();

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    final bluetoothOk = statuses[Permission.bluetoothAdvertise]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted;
    final locationOk = statuses[Permission.location]!.isGranted;

    debugPrint('[Nearby] Bluetooth: $bluetoothOk, Location: $locationOk');
    return bluetoothOk && locationOk;
  }

  Future<bool> start(String userName) async {
    _userName = userName;
    final granted = await requestPermissions();
    if (!granted) {
      debugPrint('[Nearby] Permissions denied');
      return false;
    }
    final adv = await startAdvertising();
    final disc = await startDiscovery();
    return adv || disc;
  }

  Future<void> stop() async {
    await stopAdvertising();
    await stopDiscovery();
    await _nearby.stopAllEndpoints();
    connectedEndpoints.clear();
    discoveredEndpoints.clear();
  }

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

  Future<bool> startDiscovery() async {
    try {
      final result = await _nearby.startDiscovery(
        _userName,
        _strategy,
        onEndpointFound: (id, name, serviceId) {
          discoveredEndpoints[id] = name;
          onPeerFound?.call(id, name);
        },
        onEndpointLost: (id) {
          if (id == null) return;
          final name = discoveredEndpoints.remove(id) ?? 'Unknown';
          onPeerLost?.call(id, name);
        },
        serviceId: _serviceId,
      );
      isDiscovering = result;
      onDiscoveryStatus?.call(result);
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

  Future<void> disconnectFrom(String endpointId) async {
    await _nearby.disconnectFromEndpoint(endpointId);
    final name = connectedEndpoints.remove(endpointId);
    onPeerDisconnected?.call(endpointId, name ?? 'Unknown');
  }

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

  void _onConnectionInit(String id, ConnectionInfo info) {
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (endpointId, payload) {
        if (payload.type == PayloadType.BYTES && payload.bytes != null) {
          final message = utf8.decode(payload.bytes!);
          onMessageReceived?.call(endpointId, message);
        }
      },
    );
  }

  void _onConnectionResult(String id, Status status) {
    if (status == Status.CONNECTED) {
      final name = discoveredEndpoints[id] ?? 'Unknown';
      connectedEndpoints[id] = name;
      onPeerConnected?.call(id, name);
    }
  }

  void _onDisconnected(String id) {
    final name = connectedEndpoints.remove(id);
    onPeerDisconnected?.call(id, name ?? 'Unknown');
  }

  int get connectedCount => connectedEndpoints.length;
  int get discoveredCount => discoveredEndpoints.length;
}
