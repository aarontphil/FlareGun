import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class PeersScreen extends StatefulWidget {
  const PeersScreen({super.key});

  @override
  State<PeersScreen> createState() => _PeersScreenState();
}

class _PeersScreenState extends State<PeersScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final connected = mesh.connectedPeers;
    final discovered = mesh.peers.where((p) => !p.connected).toList();
    final isActive = mesh.nearbyActive;
    final hasConnections = connected.isNotEmpty;

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
                if (isActive)
                  GestureDetector(
                    onTap: () => mesh.stopNearby(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.4)),
                      ),
                      child: const Text('Stop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                    ),
                  ),
              ],
            ),
          ),
          if (!isActive && mesh.peers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final started = await mesh.startNearby();
                        if (!started && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bluetooth permissions required. Please enable in Settings.'),
                              backgroundColor: Color(0xFFE53935),
                            ),
                          );
                        }
                      },
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 180, height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE53935).withValues(alpha: 0.04),
                              ),
                            ),
                            Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE53935).withValues(alpha: 0.06),
                              ),
                            ),
                            Container(
                              width: 80, height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                                ),
                              ),
                              child: const Icon(Icons.wifi_tethering_rounded, size: 36, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tap to broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Discover nearby devices\nvia Bluetooth',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
            ),
          if (isActive && mesh.peers.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _RipplePainter(_rippleController.value),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  final scale = 1.0 + (_pulseController.value * 0.08);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 80, height: 80,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [Color(0xFFE53935), Color(0xFFC62828)],
                                        ),
                                        boxShadow: [
                                          BoxShadow(color: Color(0x40E53935), blurRadius: 24, spreadRadius: 4),
                                        ],
                                      ),
                                      child: const Icon(Icons.wifi_tethering_rounded, size: 36, color: Colors.white),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Broadcasting...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                    const SizedBox(height: 6),
                    Text(
                      'Searching for nearby devices',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
            ),
          if (mesh.peers.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasConnections
                              ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
                              : const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFC62828)]),
                        ),
                        child: Icon(
                          hasConnections ? Icons.wifi_tethering_rounded : Icons.bluetooth_searching_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasConnections ? 'Mesh Active' : 'Scanning',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              hasConnections
                                  ? '${connected.length} connected, ${discovered.length} nearby'
                                  : '${discovered.length} devices found',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ),
                      if (hasConnections)
                        Container(
                          width: 10, height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4CAF50),
                            boxShadow: [BoxShadow(color: Color(0x604CAF50), blurRadius: 8)],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (connected.isNotEmpty) ...[
              _sectionHeader('CONNECTED  ${connected.length}'),
              ...connected.map((p) => _peerTile(context, mesh, p, true)),
              const SizedBox(height: 16),
            ],
            if (discovered.isNotEmpty) ...[
              _sectionHeader('NEARBY  ${discovered.length}'),
              ...discovered.map((p) => _peerTile(context, mesh, p, false)),
            ],
          ],
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

class _RipplePainter extends CustomPainter {
  final double progress;
  _RipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final rippleProgress = ((progress + i * 0.33) % 1.0);
      final radius = 40 + (maxRadius - 40) * rippleProgress;
      final opacity = (1.0 - rippleProgress) * 0.35;

      final paint = Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => oldDelegate.progress != progress;
}
