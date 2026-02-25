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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Text('Mesh', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const Spacer(),
                if (mesh.nearbyActive)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE53935)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (mesh.nearbyActive) {
                    await mesh.stopNearby();
                  } else {
                    final started = await mesh.startNearby();
                    if (!started && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bluetooth permissions required. Please enable in Settings.'),
                          backgroundColor: Color(0xFFE53935),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mesh.nearbyActive ? const Color(0xFF141418) : const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: mesh.nearbyActive ? const BorderSide(color: Color(0xFFE53935), width: 1.5) : BorderSide.none,
                  ),
                ),
                child: Text(
                  mesh.nearbyActive ? 'Stop Mesh' : 'Start Mesh',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
          if (mesh.nearbyActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  const SizedBox(width: 10),
                  const Text('Scanning via Bluetooth', style: TextStyle(fontSize: 12, color: Color(0xFF4A4A4E))),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (connected.isNotEmpty) ...[
            _sectionHeader('CONNECTED  ${connected.length}'),
            ...connected.map((p) => _peerTile(context, mesh, p, true)),
            const SizedBox(height: 16),
          ],
          if (discovered.isNotEmpty) ...[
            _sectionHeader('NEARBY  ${discovered.length}'),
            ...discovered.map((p) => _peerTile(context, mesh, p, false)),
          ],
          if (mesh.peers.isEmpty && mesh.nearbyActive)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_searching_rounded, size: 44, color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 14),
                    const Text('Searching...', style: TextStyle(fontSize: 15, color: Color(0xFF4A4A4E))),
                    const SizedBox(height: 4),
                    const Text(
                      'Other devices need FlareGun\nrunning with mesh started',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Color(0xFF333338)),
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
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF141418),
                      ),
                      child: const Icon(Icons.wifi_tethering_rounded, size: 36, color: Color(0xFF2A2A2E)),
                    ),
                    const SizedBox(height: 20),
                    const Text('No internet needed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6A6A6E))),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap Start Mesh to discover\nnearby devices via Bluetooth',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4E)),
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
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A4A4E), letterSpacing: 1.2),
      ),
    );
  }

  Widget _peerTile(BuildContext context, MeshProvider mesh, dynamic peer, bool isConnected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141418),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF0A0A0A)),
              child: Center(
                child: Text(
                  peer.initial,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peer.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    isConnected ? 'Connected' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                    ),
                  ),
                ],
              ),
            ),
            if (!isConnected)
              GestureDetector(
                onTap: () => mesh.connectToPeer(peer.deviceId),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            if (isConnected)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4CAF50)),
              ),
          ],
        ),
      ),
    );
  }
}
