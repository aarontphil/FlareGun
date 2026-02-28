import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaService {
  static const _modelUrl =
      'https://huggingface.co/google/gemma-3-1b-it/resolve/main/gemma-3-1b-it-gpu-int8.task';

  static const _hfToken = 'hf_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

  bool _ready = false;
  bool get isReady => _ready;
  bool get isDownloading => _downloading;
  double get downloadProgress => _progress;

  bool _downloading = false;
  double _progress = 0;
  InferenceModel? _model;

  final _onStatusChanged = StreamController<void>.broadcast();
  Stream<void> get onStatusChanged => _onStatusChanged.stream;

  static const _systemPrompt =
      'You are FlareGun AI, a disaster relief assistant running on a mobile device. '
      'You help people during emergencies with survival tips, first aid, '
      'earthquake/flood/fire safety, finding shelter, and staying safe. '
      'Give short, clear, actionable answers. '
      'If someone is in immediate danger, prioritize life-saving instructions first.';

  Future<void> init() async {
    try {
      FlutterGemma.initialize(huggingFaceToken: _hfToken);
      _ready = FlutterGemma.hasActiveModel();
      _onStatusChanged.add(null);
      if (!_ready) {
        downloadModel();
      }
    } catch (e) {
      debugPrint('[Gemma] Init error: $e');
      _ready = false;
    }
  }

  Future<void> downloadModel() async {
    if (_downloading || _ready) return;

    _downloading = true;
    _progress = 0;
    _onStatusChanged.add(null);

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(
        _modelUrl,
        token: _hfToken,
        foreground: true,
      ).withProgress((int percent) {
        _progress = percent / 100.0;
        _onStatusChanged.add(null);
      }).install();

      _ready = true;
      _downloading = false;
      _onStatusChanged.add(null);
    } catch (e) {
      debugPrint('[Gemma] Download error: $e');
      _downloading = false;
      _onStatusChanged.add(null);
    }
  }

  Future<InferenceModel> _getModel() async {
    _model ??= await FlutterGemma.getActiveModel(
      maxTokens: 1024,
      preferredBackend: PreferredBackend.gpu,
    );
    return _model!;
  }

  Stream<String> chatStream(String query) async* {
    if (!_ready) return;

    try {
      final model = await _getModel();
      final chat = await model.createChat();

      await chat.addQueryChunk(Message.text(
        text: '$_systemPrompt\n\nUser: $query',
        isUser: true,
      ));

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
    } catch (e) {
      debugPrint('[Gemma] Chat error: $e');
      yield 'AI model error. Using offline knowledge base instead.';
    }
  }

  Future<String> chat(String query) async {
    if (!_ready) return '';

    try {
      final model = await _getModel();
      final chat = await model.createChat();

      await chat.addQueryChunk(Message.text(
        text: '$_systemPrompt\n\nUser: $query',
        isUser: true,
      ));

      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
        }
      }
      return buffer.toString();
    } catch (e) {
      debugPrint('[Gemma] Chat error: $e');
      return '';
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    await _onStatusChanged.close();
  }
}
