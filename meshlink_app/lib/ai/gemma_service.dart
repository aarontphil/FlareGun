import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaService {
  bool _ready = false;
  bool get isReady => _ready;
  bool get isDownloading => _downloading;
  double get downloadProgress => _progress;

  bool _downloading = false;
  double _progress = 0;
  InferenceModel? _model;
  bool _initCalled = false;

  final _onStatusChanged = StreamController<void>.broadcast();
  Stream<void> get onStatusChanged => _onStatusChanged.stream;

  static const _systemPrompt =
      'You are FlareGun AI, a disaster relief assistant. '
      'Give short, clear, actionable answers about survival, first aid, '
      'earthquake/flood/fire safety, finding shelter, and staying safe.';

  Future<void> init() async {
    if (_initCalled) return;
    _initCalled = true;

    try {
      final hasModel = FlutterGemma.hasActiveModel();
      debugPrint('[Gemma] hasActiveModel: $hasModel');
      if (hasModel) {
        _ready = true;
        _onStatusChanged.add(null);
      } else {
        await installModel();
      }
    } catch (e) {
      debugPrint('[Gemma] init error: $e');
      _ready = false;
      await installModel();
    }
  }

  Future<void> installModel() async {
    if (_downloading || _ready) return;

    _downloading = true;
    _progress = 0;
    _onStatusChanged.add(null);
    debugPrint('[Gemma] Starting model install from bundled asset...');

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromBundled(
        'gemma3.task',
      ).install();

      _ready = true;
      _downloading = false;
      _progress = 1.0;
      _onStatusChanged.add(null);
      debugPrint('[Gemma] Model installed successfully!');
    } catch (e) {
      debugPrint('[Gemma] Install error: $e');
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
      debugPrint('[Gemma] GPU model loaded');
    } catch (gpuErr) {
      debugPrint('[Gemma] GPU failed: $gpuErr, trying CPU...');
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 256,
          preferredBackend: PreferredBackend.cpu,
        );
        debugPrint('[Gemma] CPU model loaded');
      } catch (cpuErr) {
        debugPrint('[Gemma] CPU also failed: $cpuErr');
        rethrow;
      }
    }
    return _model!;
  }

  Stream<String> chatStream(String query) async* {
    if (!_ready) {
      throw Exception('Model not installed');
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
      debugPrint('[Gemma] chatStream error: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    await _onStatusChanged.close();
  }
}
