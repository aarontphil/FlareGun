import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/mesh_provider.dart';
import '../services/location_service.dart';

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
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await context.read<MeshProvider>().sendMessageTo(widget.peerId, text);
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  bool _isDifferentDay(int ts1, int ts2) {
    final a = DateTime.fromMillisecondsSinceEpoch(ts1);
    final b = DateTime.fromMillisecondsSinceEpoch(ts2);
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final messages = mesh.getConversation(widget.peerId);
    final myId = mesh.identity.id;
    final isOnline = mesh.connectedPeers.any((p) => p.deviceId == widget.peerId);
    final isEncrypted = mesh.crypto.hasSharedKey(widget.peerId);

    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050508),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE53935), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOnline
                    ? const LinearGradient(colors: [Color(0xFF1B2E1B), Color(0xFF0E1A0E)])
                    : null,
                color: isOnline ? null : const Color(0xFF111115),
                border: isOnline
                    ? Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3))
                    : Border.all(color: const Color(0xFF1A1A1E)),
              ),
              child: Center(
                child: Text(
                  widget.peerName.isNotEmpty ? widget.peerName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  ),
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
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF333338),
                        boxShadow: isOnline
                            ? [BoxShadow(color: const Color(0xFF4CAF50).withValues(alpha: 0.4), blurRadius: 4)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(fontSize: 11, color: isOnline ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E)),
                    ),
                    if (isEncrypted) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showSafetyNumber(context, mesh),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded, size: 9, color: Color(0xFF4CAF50)),
                              SizedBox(width: 3),
                              Text('E2E', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50), letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.white.withValues(alpha: 0.06)),
                        const SizedBox(height: 12),
                        Text('No messages yet', style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.15))),
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
                      final showDate = index == 0 || _isDifferentDay(messages[index - 1].timestamp, msg.timestamp);

                      return Column(
                        children: [
                          if (showDate) _dateHeader(msg.timestamp),
                          Align(
                            alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.only(bottom: 6),
                              child: msg.hasLocation
                                  ? _locationBubble(msg, isOwn)
                                  : _messageBubble(msg, isOwn),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF050508),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.03))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111115),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF1A1A1E)),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final mesh = context.read<MeshProvider>();
                    await mesh.location.init();
                    await mesh.sendLocation(widget.peerId);
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF111115),
                      border: Border.all(color: const Color(0xFF1A1A1E)),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFFE53935), size: 18),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFE53935), Color(0xFFFF6E40)],
                      ),
                    ),
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

  Widget _messageBubble(MeshMessage msg, bool isOwn) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isOwn ? 16 : 4),
        bottomRight: Radius.circular(isOwn ? 4 : 16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: isOwn ? 0 : 8, sigmaY: isOwn ? 0 : 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            gradient: isOwn
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 4),
              bottomRight: Radius.circular(isOwn ? 4 : 16),
            ),
            border: isOwn
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.06)),
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
                    style: TextStyle(fontSize: 10, color: isOwn ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.2)),
                  ),
                  if (isOwn) ...[
                    const SizedBox(width: 4),
                    _statusIcon(msg.status, isOwn),
                  ],
                  if (msg.encrypted) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.lock_rounded, size: 9, color: isOwn ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF4CAF50).withValues(alpha: 0.5)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationBubble(MeshMessage msg, bool isOwn) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isOwn ? 16 : 4),
          bottomRight: Radius.circular(isOwn ? 4 : 16),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOwn
              ? [const Color(0xFFE53935), const Color(0xFFD32F2F)]
              : [const Color(0xFF1A1420), const Color(0xFF0E0E12)],
        ),
        border: isOwn ? null : Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE53935).withValues(alpha: isOwn ? 0.3 : 0.15),
                ),
                child: Icon(Icons.location_on_rounded, size: 14, color: isOwn ? Colors.white : const Color(0xFFE53935)),
              ),
              const SizedBox(width: 10),
              Text('Shared Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOwn ? Colors.white.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.5))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            LocationService.formatCoords(msg.latitude!, msg.longitude!),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isOwn ? Colors.white : Colors.white.withValues(alpha: 0.9), letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: isOwn ? 0.15 : 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_new_rounded, size: 12, color: isOwn ? Colors.white.withValues(alpha: 0.7) : const Color(0xFFE53935)),
                const SizedBox(width: 6),
                Text('Open in Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isOwn ? Colors.white.withValues(alpha: 0.7) : const Color(0xFFE53935))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(_formatTime(msg.timestamp), style: TextStyle(fontSize: 10, color: isOwn ? Colors.white.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.2))),
          ),
        ],
      ),
    );
  }

  Widget _dateHeader(int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    String text;
    if (d.day == now.day && d.month == now.month && d.year == now.year) {
      text = 'Today';
    } else {
      text = '${d.day}/${d.month}/${d.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF111115),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1A1A1E)),
          ),
          child: Text(text, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.3))),
        ),
      ),
    );
  }

  Widget _statusIcon(MessageStatus status, bool isOwn) {
    final color = isOwn ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.3);
    IconData icon;
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule_rounded;
      case MessageStatus.sent:
        icon = Icons.check_rounded;
      case MessageStatus.delivered:
        icon = Icons.done_all_rounded;
      case MessageStatus.read:
        icon = Icons.done_all_rounded;
    }
    return Icon(icon, size: 12, color: status == MessageStatus.read ? const Color(0xFF4CAF50) : color);
  }

  void _showSafetyNumber(BuildContext context, MeshProvider mesh) {
    final safetyNum = mesh.crypto.getSafetyNumber(widget.peerId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Color(0xFF111115),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.verified_user_rounded, color: Color(0xFF4CAF50), size: 22),
            ),
            const SizedBox(height: 16),
            const Text('Safety Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Text(
              safetyNum,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: 10, color: Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            Text(
              'Compare this number with ${widget.peerName} in person.\nIf they match, your connection is secure.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.4), height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
