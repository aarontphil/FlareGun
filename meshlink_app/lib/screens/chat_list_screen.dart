import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final connected = mesh.connectedPeers;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1E),
                    border: Border.all(color: const Color(0xFF2A2A2E)),
                  ),
                  child: Center(child: Text(mesh.identity.emoji, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Chats',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
                const Spacer(),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: mesh.nearbyActive || mesh.wsConnected
                        ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
                        : const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mesh.nearbyActive || mesh.wsConnected
                              ? const Color(0xFF4CAF50) : const Color(0xFF5A5A5E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mesh.nearbyActive ? 'Mesh' : mesh.wsConnected ? 'Relay' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: mesh.nearbyActive || mesh.wsConnected
                              ? const Color(0xFF81C784) : const Color(0xFF5A5A5E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                  const SizedBox(width: 10),
                  Text('Search', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 15)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Chat list
          Expanded(
            child: connected.isEmpty
                ? _emptyState(context, mesh)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: connected.length,
                    itemBuilder: (context, index) {
                      final peer = connected[index];
                      final lastMsg = mesh.lastMessage(peer.deviceId);
                      final unread = mesh.unreadCount(peer.deviceId);

                      return _chatTile(context, peer, lastMsg, unread);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext context, dynamic peer, dynamic lastMsg, int unread) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(peerId: peer.deviceId, peerName: peer.name, peerEmoji: peer.emoji),
        ));
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1E),
                border: Border.all(color: const Color(0xFF2A2A2E)),
              ),
              child: Center(child: Text(peer.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 14),

            // Name + message preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg?.text ?? 'Tap to start chatting',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: lastMsg != null ? 0.5 : 0.25),
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time + unread
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMsg != null)
                  Text(
                    _formatTime(lastMsg.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                if (unread > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, MeshProvider mesh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
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
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: Color(0xFF3A3A3E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF8A8A8E)),
            ),
            const SizedBox(height: 8),
            Text(
              mesh.nearbyActive
                  ? 'Waiting for peers to connect...'
                  : 'Go to Discover to find nearby devices',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A5E)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    return '${d.day}/${d.month}';
  }
}
