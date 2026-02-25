import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _serverController = TextEditingController();
  bool _nameSaved = false;

  @override
  void initState() {
    super.initState();
    final mesh = context.read<MeshProvider>();
    _nameController.text = mesh.identity.name;
    _serverController.text = mesh.serverUrl;
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
            const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
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
                          color: const Color(0xFF0A0A0A),
                          border: Border.all(color: const Color(0xFF1E1E22), width: 2),
                        ),
                        child: Center(
                          child: Text(
                            mesh.identity.initial,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFE53935)),
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
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                            color: _nameSaved ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _nameSaved ? 'Saved' : 'Save',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => mesh.connectRelay(_serverController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E22),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Connect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Optional. Mesh works offline via Bluetooth.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF333338)),
                  ),
                ],
              ),
            ),
            _section(
              'Status',
              Column(
                children: [
                  _stat('Mesh', mesh.nearbyActive ? 'Active' : 'Inactive'),
                  _stat('Relay', mesh.wsConnected ? 'Connected' : 'Off'),
                  _stat('Peers', '${mesh.peerCount}'),
                  _stat('Messages', '${mesh.broadcastMessages.length}'),
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
                        backgroundColor: const Color(0xFF141418),
                        title: const Text('Clear all data?', style: TextStyle(fontSize: 16)),
                        content: const Text('This will delete all messages.', style: TextStyle(fontSize: 14)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
                    backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFE53935),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Clear All Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Column(
                children: [
                  Text('FlareGun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF4A4A4E))),
                  SizedBox(height: 2),
                  Text('v2.0', style: TextStyle(fontSize: 11, color: Color(0xFF333338))),
                ],
              ),
            ),
          ],
        ),
      ),
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
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6A6A6E))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverController.dispose();
    super.dispose();
  }
}
