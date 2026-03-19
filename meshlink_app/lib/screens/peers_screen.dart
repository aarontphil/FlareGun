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
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
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
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                  ).createShader(bounds),
                  child: const Text('Mesh', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white)),
                ),
                const Spacer(),
                if (isActive)
                  GestureDetector(
                    onTap: () => mesh.stopNearby(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                      ),
                      child: const Text('Stop', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
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
                              content: Text('Bluetooth permissions required'),
                              backgroundColor: Color(0xFFE53935),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0E0E12),
                          border: Border.all(color: const Color(0xFF1A1A1E), width: 1),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 130, height: 130,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1A1A1E), width: 0.5),
                              ),
                            ),
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1A1A1E), width: 0.5),
                              ),
                            ),
                            Container(
                              width: 56, height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                                ),
                              ),
                              child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 26),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Tap to broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(
                      'Discover nearby devices via Bluetooth',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.25)),
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
                      width: 220, height: 220,
                      child: AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _RadarPainter(
                              sweepAngle: _sweepController.value * 2 * pi,
                              pulseValue: _pulseController.value,
                              peers: const [],
                            ),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, _) {
                                  return Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE53935).withValues(alpha: 0.2 + _pulseController.value * 0.15),
                                          blurRadius: 20 + _pulseController.value * 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 22),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                      ).createShader(bounds),
                      child: const Text('Broadcasting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                    Text('Searching for nearby devices', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.25))),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: hasConnections
                          ? [const Color(0xFF1B2E1B), const Color(0xFF0E1A0E)]
                          : [const Color(0xFF1E1418), const Color(0xFF140E10)],
                    ),
                    border: Border.all(
                      color: hasConnections
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : const Color(0xFFE53935).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: hasConnections
                              ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
                              : const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6E40)]),
                        ),
                        child: Icon(
                          hasConnections ? Icons.wifi_tethering_rounded : Icons.bluetooth_searching_rounded,
                          size: 18, color: Colors.white,
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
                                  ? '${connected.length} connected  ·  ${discovered.length} nearby'
                                  : '${discovered.length} devices found',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                            ),
                          ],
                        ),
                      ),
                      if (hasConnections)
                        Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF4CAF50),
                            boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 8)],
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
          color: const Color(0xFF111115),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A1A1E), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isConnected
                    ? const LinearGradient(colors: [Color(0xFF1B2E1B), Color(0xFF0E1A0E)])
                    : null,
                color: isConnected ? null : const Color(0xFF0A0A0A),
                border: isConnected
                    ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))
                    : null,
              ),
              child: Center(
                child: Text(
                  peer.initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isConnected ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  ),
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
                    gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6E40)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            if (isConnected)
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50),
                  boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.5), blurRadius: 6)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double pulseValue;
  final List<Offset> peers;
  _RadarPainter({required this.sweepAngle, required this.pulseValue, required this.peers});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Grid rings
    for (int i = 1; i <= 3; i++) {
      final r = maxR * i / 3;
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = const Color(0xFFE53935).withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Cross lines
    final linePaint = Paint()
      ..color = const Color(0xFFE53935).withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(center.dx, center.dy - maxR), Offset(center.dx, center.dy + maxR), linePaint);
    canvas.drawLine(Offset(center.dx - maxR, center.dy), Offset(center.dx + maxR, center.dy), linePaint);

    // Sweep cone
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          const Color(0xFFE53935).withValues(alpha: 0.15),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, sweepPaint);

    // Sweep line
    final lineEnd = Offset(
      center.dx + maxR * cos(sweepAngle),
      center.dy + maxR * sin(sweepAngle),
    );
    canvas.drawLine(
      center, lineEnd,
      Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: 0.5)
        ..strokeWidth = 1.5,
    );

    // Ripple rings
    for (int i = 0; i < 3; i++) {
      final ripple = ((pulseValue + i * 0.33) % 1.0);
      final r = 24 + (maxR - 24) * ripple;
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = const Color(0xFFE53935).withValues(alpha: (1 - ripple) * 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
