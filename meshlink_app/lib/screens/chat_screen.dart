import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/mesh_provider.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({super.key, required this.peerId, required this.peerName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeshProvider>().markConversationRead(widget.peerId);
    });
  }

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
    final isOnline = mesh.connectedPeers.any((p) => p.deviceId == widget.peerId);
    final isEncrypted = mesh.crypto.hasSharedKey(widget.peerId);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE53935), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF1E1E22)),
              child: Center(
                child: Text(
                  widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFE53935)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.peerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text(
                      isOnline ? 'Connected' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                      ),
                    ),
                    if (isEncrypted) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded, size: 10, color: Color(0xFF4CAF50)),
                      const SizedBox(width: 2),
                      const Text('E2E', style: TextStyle(fontSize: 10, color: Color(0xFF4CAF50))),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'Send a message',
                      style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.15)),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isOwn = msg.senderId == myId;
                      final showDate = index == 0 || _isDifferentDay(messages[index - 1].timestamp, msg.timestamp);

                      return Column(
                        children: [
                          if (showDate) _dateHeader(msg.timestamp),
                          Align(
                            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                              decoration: BoxDecoration(
                                color: isOwn ? const Color(0xFFE53935) : const Color(0xFF141418),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isOwn ? 16 : 4),
                                  bottomRight: Radius.circular(isOwn ? 4 : 16),
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
                                        fontSize: 14,
                                        height: 1.4,
                                        color: isOwn ? Colors.white : Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatTime(msg.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isOwn
                                              ? Colors.white.withValues(alpha: 0.5)
                                              : Colors.white.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      if (isOwn) ...[
                                        const SizedBox(width: 4),
                                        _statusIcon(msg.status, isOwn),
                                      ],
                                    ],
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
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 10, 10 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF141418))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141418),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusIcon(MessageStatus status, bool isOwn) {
    final color = isOwn ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3);
    String label;
    switch (status) {
      case MessageStatus.sending:
        label = 'Sending';
      case MessageStatus.sent:
        label = 'Sent';
      case MessageStatus.delivered:
        label = 'Delivered';
      case MessageStatus.read:
        label = 'Read';
    }
    return Text(label, style: TextStyle(fontSize: 9, color: color));
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4A4A4E))),
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
