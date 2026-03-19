import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final allPeers = mesh.peers.where((p) => p.deviceId != mesh.identity.id).toList();

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
                  child: const Text(
                    'Chats',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: mesh.nearbyActive || mesh.wsConnected
                        ? const Color(0xFF1B5E20).withValues(alpha: 0.25)
                        : const Color(0xFF1E1E22),
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
                              ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        mesh.nearbyActive ? '${mesh.peerCount} peers' : mesh.wsConnected ? 'Relay' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: mesh.nearbyActive || mesh.wsConnected
                              ? const Color(0xFF81C784) : const Color(0xFF4A4A4E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF141418),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.2), size: 18),
                  const SizedBox(width: 10),
                  Text('Search', style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: allPeers.isEmpty
                ? _emptyState(mesh)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: allPeers.length,
                    itemBuilder: (context, index) {
                      final peer = allPeers[index];
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
          builder: (_) => ChatScreen(peerId: peer.deviceId, peerName: peer.name),
        ));
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E22),
              ),
              child: Center(
                child: Text(
                  peer.initial,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg?.text ?? 'Tap to start chatting',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: lastMsg != null ? 0.4 : 0.2),
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMsg != null)
                  Text(
                    _formatTime(lastMsg.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.25)),
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
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
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

  Widget _emptyState(MeshProvider mesh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF141418),
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded, size: 32, color: Color(0xFF2A2A2E)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No conversations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF6A6A6E)),
            ),
            const SizedBox(height: 6),
            Text(
              mesh.nearbyActive
                  ? 'Waiting for peers...'
                  : 'Start mesh from the Mesh tab',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4A4A4E)),
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
