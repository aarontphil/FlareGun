import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;
  final String peerEmoji;

  const ChatScreen({super.key, required this.peerId, required this.peerName, required this.peerEmoji});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final mesh = context.read<MeshProvider>();
    await mesh.sendMessageTo(widget.peerId, text);
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final messages = mesh.getConversation(widget.peerId);
    final myId = mesh.identity.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE53935)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1E),
                border: Border.all(color: const Color(0xFF2A2A2E)),
              ),
              child: Center(child: Text(widget.peerEmoji, style: const TextStyle(fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  mesh.connectedPeers.any((p) => p.deviceId == widget.peerId) ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: mesh.connectedPeers.any((p) => p.deviceId == widget.peerId)
                        ? const Color(0xFF4CAF50) : const Color(0xFF5A5A5E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // Messages
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 40, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 12),
                        Text(
                          'End-to-end encrypted',
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isOwn = msg.senderId == myId;

                      // Show date header
                      final showDate = index == 0 || _isDifferentDay(
                        messages[index - 1].timestamp, msg.timestamp,
                      );

                      return Column(
                        children: [
                          if (showDate) _dateHeader(msg.timestamp),
                          Align(
                            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                              decoration: BoxDecoration(
                                color: isOwn ? const Color(0xFFE53935) : const Color(0xFF1A1A1E),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(18),
                                  topRight: const Radius.circular(18),
                                  bottomLeft: Radius.circular(isOwn ? 18 : 4),
                                  bottomRight: Radius.circular(isOwn ? 4 : 18),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.35,
                                        color: isOwn ? Colors.white : Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(msg.timestamp),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOwn
                                          ? Colors.white.withValues(alpha: 0.6)
                                          : Colors.white.withValues(alpha: 0.25),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Compose bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 10, 10 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border: Border(top: BorderSide(color: const Color(0xFF1A1A1E))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(Icons.emoji_emotions_outlined, color: Colors.white.withValues(alpha: 0.3), size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: const TextStyle(fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        Icon(Icons.attach_file_rounded, color: Colors.white.withValues(alpha: 0.3), size: 22),
                        const SizedBox(width: 10),
                        Icon(Icons.camera_alt_outlined, color: Colors.white.withValues(alpha: 0.3), size: 22),
                        const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateHeader(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    String label;
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      label = 'Today';
    } else {
      label = '${d.day}/${d.month}/${d.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5A5A5E))),
        ),
      ),
    );
  }

  bool _isDifferentDay(int ts1, int ts2) {
    final d1 = DateTime.fromMillisecondsSinceEpoch(ts1);
    final d2 = DateTime.fromMillisecondsSinceEpoch(ts2);
    return d1.day != d2.day || d1.month != d2.month || d1.year != d2.year;
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
