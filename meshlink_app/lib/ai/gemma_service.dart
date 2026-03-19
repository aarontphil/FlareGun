import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaService {
  static const _hfToken = String.fromEnvironment('HF_TOKEN');

  bool _ready = false;
  bool get isReady => _ready;
  bool get isDownloading => _downloading;
  double get downloadProgress => _progress;
  String? get lastError => _lastError;

  bool _downloading = false;
  double _progress = 0;
  String? _lastError;
  InferenceModel? _model;
  bool _initCalled = false;

  final _onStatusChanged = StreamController<void>.broadcast();
  Stream<void> get onStatusChanged => _onStatusChanged.stream;

  static const _systemPrompt =
      'You are FlareGun AI, a disaster relief assistant. '
      'Give short, clear, actionable answers about survival, first aid, '
      'earthquake/flood/fire safety, finding shelter, and staying safe. '
      'If in immediate danger, prioritize life-saving instructions.';

  Future<void> init() async {
    if (_initCalled) return;
    _initCalled = true;
    debugPrint('[Gemma] init() called');

    try {
      final hasModel = FlutterGemma.hasActiveModel();
      debugPrint('[Gemma] hasActiveModel: $hasModel');
      if (hasModel) {
        _ready = true;
        _onStatusChanged.add(null);
      }
    } catch (e) {
      debugPrint('[Gemma] check model error: $e');
      _ready = false;
    }
  }

  Future<void> installModel() async {
    if (_downloading || _ready) return;

    if (_hfToken.isEmpty) {
      _lastError = "Missing HF_TOKEN format. Build app with --dart-define=HF_TOKEN=your_token";
      _onStatusChanged.add(null);
      return;
    }

    _downloading = true;
    _progress = 0;
    _lastError = null;
    _onStatusChanged.add(null);
    debugPrint('[Gemma] Starting network install...');

    try {
      // Use Modern API to download model from network
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromNetwork(
        'https://huggingface.co/google/gemma-3-1b-it/resolve/main/gemma-3-1b-it-gpu-int4.task',
        token: _hfToken,
      ).withProgress((progress) {
        _progress = progress / 100.0;
        _onStatusChanged.add(null);
        debugPrint('[Gemma] Downloading: ${progress}%');
      }).install();

      _ready = true;
      _downloading = false;
      _progress = 1.0;
      _onStatusChanged.add(null);
      debugPrint('[Gemma] Model installed successfully');
    } catch (e) {
      debugPrint('[Gemma] Install error: $e');
      _lastError = e.toString();
      _downloading = false;
      _ready = false;
      _onStatusChanged.add(null);
    }
  }

  Future<InferenceModel> _getModel() async {
    if (_model != null) return _model!;

    try {
      debugPrint('[Gemma] Getting active model (GPU)...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (gpuErr) {
      debugPrint('[Gemma] GPU failed ($gpuErr), trying CPU...');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 256,
        preferredBackend: PreferredBackend.cpu,
      );
    }
    return _model!;
  }

  Stream<String> chatStream(String query) async* {
    if (!_ready) {
      throw Exception('Model not ready');
    }

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
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    await _onStatusChanged.close();
  }
}
