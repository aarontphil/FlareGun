import 'dart:async';
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
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _chat.add({
      'role': 'assistant',
      'text': 'I am your disaster relief AI. Ask me about survival, first aid, or emergency procedures.\n\nI run entirely on your device with no internet needed.',
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || _generating) return;

    setState(() {
      _chat.add({'role': 'user', 'text': text});
      _chat.add({'role': 'assistant', 'text': ''});
      _generating = true;
    });
    _controller.clear();
    _scrollDown();

    final mesh = context.read<MeshProvider>();
    final responseIndex = _chat.length - 1;
    StreamSubscription<String>? sub;

    sub = mesh.aiChatStream(text).listen(
      (chunk) {
        setState(() {
          _chat[responseIndex] = {
            'role': 'assistant',
            'text': (_chat[responseIndex]['text'] ?? '') + chunk,
          };
        });
        _scrollDown();
      },
      onDone: () {
        setState(() => _generating = false);
        sub?.cancel();
      },
      onError: (_) {
        setState(() {
          _generating = false;
          if ((_chat[responseIndex]['text'] ?? '').isEmpty) {
            _chat[responseIndex] = {
              'role': 'assistant',
              'text': 'Something went wrong. Please try again.',
            };
          }
        });
        sub?.cancel();
      },
    );
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mesh = context.watch<MeshProvider>();
    final gemma = mesh.gemma;
    final modelReady = gemma.isReady;

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
                    color: modelReady
                        ? const Color(0xFF1B5E20).withValues(alpha: 0.25)
                        : const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        modelReady ? Icons.psychology_rounded : Icons.cloud_download_rounded,
                        size: 12,
                        color: modelReady ? const Color(0xFF4CAF50) : const Color(0xFF4A4A4E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        modelReady ? 'Gemma 3 LLM' : 'Keyword mode',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: modelReady ? const Color(0xFF81C784) : const Color(0xFF4A4A4E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!gemma.isReady && !gemma.isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: GestureDetector(
                onTap: () => gemma.installModel(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.download_rounded, color: Color(0xFFE53935), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Download Gemma 3 LLM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2),
                            Text('1.3 GB - enables real AI responses', style: TextStyle(fontSize: 11, color: Color(0xFF4A4A4E))),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF4A4A4E), size: 14),
                    ],
                  ),
                ),
              ),
            ),
          if (gemma.isDownloading)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141418),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE53935)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Downloading model... ${(gemma.downloadProgress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: gemma.downloadProgress,
                        backgroundColor: const Color(0xFF1E1E22),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFE53935)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                _chip('SOS', 'I need emergency help right now'),
                _chip('Earthquake', 'What should I do during an earthquake?'),
                _chip('First Aid', 'How do I perform basic first aid?'),
                _chip('Fire', 'How do I escape a fire?'),
                _chip('Flood', 'What are flood safety tips?'),
                _chip('CPR', 'How do I perform CPR?'),
                _chip('Shelter', 'How do I build an emergency shelter?'),
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
                final text = msg['text'] ?? '';
                final isCurrentlyGenerating = _generating && index == _chat.length - 1 && !isUser;

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
                    child: text.isEmpty && isCurrentlyGenerating
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A4A4E)),
                              ),
                              SizedBox(width: 10),
                              Text('Thinking...', style: TextStyle(fontSize: 13, color: Color(0xFF4A4A4E))),
                            ],
                          )
                        : Text(
                            text,
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
                      enabled: !_generating,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: modelReady ? 'Ask the AI anything...' : 'Ask about survival...',
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
                  onTap: _generating ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _generating ? const Color(0xFF4A4A4E) : const Color(0xFFE53935),
                      shape: BoxShape.circle,
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

  Widget _chip(String label, String query) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _generating ? null : () {
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
