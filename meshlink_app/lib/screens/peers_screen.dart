import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class PeersScreen extends StatelessWidget {
  const PeersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final connected = mesh.connectedPeers;
    final discovered = mesh.peers.where((p) => !p.connected).toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Icon(Icons.radar_rounded, color: Color(0xFFE53935), size: 28),
                const SizedBox(width: 12),
                const Text('Discover', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Start/Stop button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  if (mesh.nearbyActive) {
                    await mesh.stopNearby();
                  } else {
                    await mesh.startNearby();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mesh.nearbyActive ? const Color(0xFF1A1A1E) : const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: mesh.nearbyActive
                        ? const BorderSide(color: Color(0xFFE53935))
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(mesh.nearbyActive ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      mesh.nearbyActive ? 'Stop Mesh' : 'Start Mesh',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (mesh.nearbyActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  _pulseDot(),
                  const SizedBox(width: 8),
                  const Text(
                    'Scanning for nearby devices via Bluetooth...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A5A5E)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Connected peers
          if (connected.isNotEmpty) ...[
            _sectionHeader('CONNECTED  ·  ${connected.length}'),
            ...connected.map((p) => _peerTile(context, mesh, p, true)),
            const SizedBox(height: 16),
          ],

          // Discovered peers
          if (discovered.isNotEmpty) ...[
            _sectionHeader('DISCOVERED  ·  ${discovered.length}'),
            ...discovered.map((p) => _peerTile(context, mesh, p, false)),
          ],

          // Empty hint
          if (mesh.peers.isEmpty && mesh.nearbyActive)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_searching_rounded, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    const Text('Searching nearby...', style: TextStyle(fontSize: 16, color: Color(0xFF5A5A5E))),
                    const SizedBox(height: 6),
                    const Text(
                      'Make sure other devices also have\nMeshLink running with Mesh started',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF3A3A3E)),
                    ),
                  ],
                ),
              ),
            ),

          if (!mesh.nearbyActive && mesh.peers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1E),
                        border: Border.all(color: const Color(0xFF2A2A2E)),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded, size: 40, color: Color(0xFF3A3A3E)),
                    ),
                    const SizedBox(height: 24),
                    const Text('No internet needed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF8A8A8E))),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap "Start Mesh" to discover nearby\ndevices via Bluetooth & WiFi Direct',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF5A5A5E)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5A5A5E), letterSpacing: 1),
      ),
    );
  }

  Widget _peerTile(BuildContext context, MeshProvider mesh, dynamic peer, bool connected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(14),
          border: connected ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D0D0D),
                border: Border.all(color: const Color(0xFF2A2A2E)),
              ),
              child: Center(child: Text(peer.emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peer.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    connected ? 'Connected via Bluetooth' : 'Available nearby',
                    style: TextStyle(
                      fontSize: 12,
                      color: connected ? const Color(0xFF4CAF50) : const Color(0xFF5A5A5E),
                    ),
                  ),
                ],
              ),
            ),
            if (!connected)
              GestureDetector(
                onTap: () => mesh.connectToPeer(peer.deviceId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            if (connected)
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pulseDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (_, val, child) => Opacity(opacity: val, child: child),
      onEnd: () {},
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE53935)),
      ),
    );
  }
}
