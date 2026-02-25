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

  @override
  void initState() {
    super.initState();
    _chat.add({
      'role': 'assistant',
      'text': 'I am your offline AI assistant. I run entirely on your device — no server or internet needed.\n\nAsk me about disaster survival, first aid, or emergency procedures.',
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _chat.add({'role': 'user', 'text': text});
    });
    _controller.clear();

    final mesh = context.read<MeshProvider>();
    final response = mesh.aiChat(text);

    setState(() {
      _chat.add({'role': 'assistant', 'text': response});
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Text('AI Assistant', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt_rounded, size: 12, color: Color(0xFF4CAF50)),
                      SizedBox(width: 4),
                      Text('On-device', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF81C784))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                _chip('SOS', 'emergency sos help'),
                _chip('Earthquake', 'earthquake safety tips'),
                _chip('First Aid', 'first aid basics'),
                _chip('Fire', 'fire escape plan'),
                _chip('Flood', 'flood safety'),
                _chip('CPR', 'cpr guide'),
                _chip('Shelter', 'emergency shelter'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chat.length,
              itemBuilder: (context, index) {
                final msg = _chat[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFE53935) : const Color(0xFF141418),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 10, 10 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF141418)))),
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
                        hintText: 'Ask about survival...',
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
            color: const Color(0xFF141418),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1E1E22)),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6A6A6E))),
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
