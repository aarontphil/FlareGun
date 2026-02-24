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

  static const _avatars = ['🧑‍🚀', '🧑‍🚒', '🧑‍⚕️', '🦺', '📡', '🟢', '🔵', '🟣', '🟠', '🔴', '🟡', '⚪', '🎯', '💎', '⚡', '🔥'];

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
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const SizedBox(height: 28),

            // Identity
            _section(
              'Identity',
              Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showAvatarPicker(),
                        child: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0D0D0D),
                            border: Border.all(color: const Color(0xFF2A2A2E), width: 2),
                          ),
                          child: Center(child: Text(mesh.identity.emoji, style: const TextStyle(fontSize: 30))),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tap avatar to change', style: TextStyle(fontSize: 12, color: Color(0xFF5A5A5E))),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${mesh.identity.id.substring(0, 8)}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF3A3A3E)),
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
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Display name',
                            filled: true,
                            fillColor: const Color(0xFF0D0D0D),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
                            _nameSaved ? '✓' : 'Save',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Relay Server (Optional)
            _section(
              'Relay Server (Optional)',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mesh.wsConnected ? const Color(0xFF4CAF50) : const Color(0xFF5A5A5E),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mesh.wsConnected ? 'Connected to ${mesh.serverUrl}' : 'Not connected',
                        style: TextStyle(
                          fontSize: 13,
                          color: mesh.wsConnected ? const Color(0xFF4CAF50) : const Color(0xFF5A5A5E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '192.168.1.100:8000',
                      filled: true,
                      fillColor: const Color(0xFF0D0D0D),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => mesh.connectRelay(_serverController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A2A2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Relay is optional — mesh works without it via Bluetooth',
                    style: TextStyle(fontSize: 11, color: Color(0xFF3A3A3E)),
                  ),
                ],
              ),
            ),

            // Network Status
            _section(
              'Status',
              Column(
                children: [
                  _stat('Mesh Mode', mesh.nearbyActive ? 'Active (BLE)' : 'Inactive'),
                  _stat('Relay Mode', mesh.wsConnected ? 'Connected' : 'Offline'),
                  _stat('Connected Peers', '${mesh.peerCount}'),
                  _stat('Total Messages', '${mesh.broadcastMessages.length}'),
                ],
              ),
            ),

            // Danger zone
            _section(
              'Data',
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF1A1A1E),
                        title: const Text('Clear all data?'),
                        content: const Text('This will delete all messages.'),
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
                  child: const Text('Clear All Data', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // About
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text('MeshLink', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF5A5A5E))),
                  const SizedBox(height: 4),
                  const Text('v2.0 · Offline Mesh Communication', style: TextStyle(fontSize: 12, color: Color(0xFF3A3A3E))),
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
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5A5A5E), letterSpacing: 0.5)),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8A8A8E))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF3A3A3E), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choose Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatars.map((emoji) => GestureDetector(
                onTap: () {
                  context.read<MeshProvider>().setDeviceEmoji(emoji);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0D0D0D),
                    border: Border.all(
                      color: emoji == context.read<MeshProvider>().identity.emoji
                          ? const Color(0xFFE53935) : const Color(0xFF2A2A2E),
                      width: 2,
                    ),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
