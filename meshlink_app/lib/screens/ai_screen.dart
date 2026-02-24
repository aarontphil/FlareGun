import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mesh_provider.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, String>> _chat = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chat.add({
      'role': 'assistant',
      'text': 'Hi! I\'m your offline AI assistant. I can help with disaster preparedness, first aid, and emergency procedures.\n\nAsk me anything.',
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _loading = true;
    });
    _controller.clear();

    final mesh = context.read<MeshProvider>();
    final response = await mesh.aiChat(text);

    setState(() {
      _loading = false;
      _chat.add({
        'role': 'assistant',
        'text': response?['text'] ?? 'Server unavailable. Connect to relay in Settings for AI features.',
      });
    });

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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFE53935), size: 28),
                const SizedBox(width: 12),
                const Text('AI Assistant', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Phase 2',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF5A5A5E)),
                  ),
                ),
              ],
            ),
          ),

          // Quick actions
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                _chip('🚨 SOS', 'emergency sos help'),
                _chip('🌍 Earthquake', 'earthquake safety'),
                _chip('🏥 First Aid', 'first aid'),
                _chip('🔥 Fire', 'fire escape'),
                _chip('🌊 Flood', 'flood safety'),
              ],
            ),
          ),

          // Chat
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chat.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _chat.length && _loading) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935))),
                        const SizedBox(width: 10),
                        Text('Thinking...', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                      ],
                    ),
                  );
                }

                final msg = _chat[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFE53935) : const Color(0xFF1A1A1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 10, 10 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1A1A1E))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Ask about disaster survival...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
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

  Widget _chip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          _controller.text = query;
          _send();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A2E)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8E))),
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
