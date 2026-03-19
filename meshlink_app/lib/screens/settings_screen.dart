import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  bool _nameSaved = false;
  late AnimationController _counterAnim;

  @override
  void initState() {
    super.initState();
    final mesh = context.read<MeshProvider>();
    _nameController.text = mesh.identity.name;
    _serverController.text = mesh.serverUrl;
    _counterAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
              ).createShader(bounds),
              child: const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white)),
            ),
            const SizedBox(height: 28),
            _section(
              'Identity',
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.2), blurRadius: 16, spreadRadius: 2),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            mesh.identity.initial,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(mesh.identity.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                              mesh.identity.id.substring(0, 8),
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF333338)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Display name',
                            filled: true,
                            fillColor: const Color(0xFF0A0A0A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A1A1E))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A1A1E))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935))),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          await mesh.setDeviceName(_nameController.text.trim());
                          setState(() => _nameSaved = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) setState(() => _nameSaved = false);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: _nameSaved
                                ? const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)])
                                : const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF6E40)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _nameSaved ? 'Saved' : 'Save',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              'Relay Server',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mesh.wsConnected ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                          boxShadow: mesh.wsConnected
                              ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 6)]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mesh.wsConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          fontSize: 13,
                          color: mesh.wsConnected ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '192.168.1.100:8000',
                      filled: true,
                      fillColor: const Color(0xFF0A0A0A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A1A1E))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1A1A1E))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE53935))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => mesh.connectRelay(_serverController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111115),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF1A1A1E)),
                        ),
                      ),
                      child: const Text('Connect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Optional. Mesh works offline via Bluetooth.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ],
              ),
            ),
            _section(
              'Network Stats',
              AnimatedBuilder(
                animation: _counterAnim,
                builder: (context, _) {
                  final t = _counterAnim.value;
                  return Column(
                    children: [
                      Row(
                        children: [
                          _statCard('Peers', '${(mesh.peerCount * t).round()}', const Color(0xFFE53935)),
                          const SizedBox(width: 10),
                          _statCard('Messages', '${(mesh.broadcastMessages.length * t).round()}', const Color(0xFFFF6E40)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statCard('Mesh', mesh.nearbyActive ? 'Active' : 'Off', const Color(0xFF4CAF50)),
                          const SizedBox(width: 10),
                          _statCard('Relay', mesh.wsConnected ? 'On' : 'Off', const Color(0xFF42A5F5)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _meshHealthBar(mesh),
                    ],
                  );
                },
              ),
            ),
            _section(
              'Security',
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF4CAF50)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('End-to-End Encryption', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('X25519 + AES-256-GCM', style: TextStyle(fontSize: 11, color: Color(0xFF4A4A4E))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
                        ),
                        child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF42A5F5)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Forward Secrecy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('HKDF key ratcheting', style: TextStyle(fontSize: 11, color: Color(0xFF4A4A4E))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFF42A5F5).withValues(alpha: 0.2)),
                        ),
                        child: const Text('Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF42A5F5))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFF6E40).withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.timer_rounded, size: 16, color: Color(0xFFFF6E40)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Message Expiry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('Auto-purge after 24 hours', style: TextStyle(fontSize: 11, color: Color(0xFF4A4A4E))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFFF6E40).withValues(alpha: 0.1),
                          border: Border.all(color: const Color(0xFFFF6E40).withValues(alpha: 0.2)),
                        ),
                        child: const Text('24h', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFFF6E40))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _section(
              'Data',
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF111115),
                        title: const Text('Clear all data?', style: TextStyle(fontSize: 16)),
                        content: const Text('This will delete all messages and reset encryption keys.', style: TextStyle(fontSize: 14)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Color(0xFF4A4A4E)))),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Clear', style: TextStyle(color: Color(0xFFE53935))),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<MeshProvider>().clearData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.08),
                    foregroundColor: const Color(0xFFE53935),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: const Color(0xFFE53935).withValues(alpha: 0.15)),
                    ),
                  ),
                  child: const Text('Clear All Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                    ).createShader(bounds),
                    child: const Text('FlareGun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const SizedBox(height: 2),
                  Text('v2.0', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.2))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.06),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.35))),
          ],
        ),
      ),
    );
  }

  Widget _meshHealthBar(MeshProvider mesh) {
    final score = (mesh.nearbyActive ? 0.4 : 0.0) + (mesh.wsConnected ? 0.2 : 0.0) + (mesh.peerCount > 0 ? 0.4 : 0.0);
    final label = score >= 0.8 ? 'Excellent' : score >= 0.4 ? 'Good' : 'Low';
    final color = score >= 0.8 ? const Color(0xFF4CAF50) : score >= 0.4 ? const Color(0xFFFF6E40) : const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mesh Health', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4))),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 4,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4A4A4E), letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A1A1E), width: 0.5),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    _counterAnim.dispose();
    super.dispose();
  }
}
