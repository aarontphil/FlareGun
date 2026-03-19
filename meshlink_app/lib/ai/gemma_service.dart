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
      _ready = FlutterGemma.hasActiveModel();
      _onStatusChanged.add(null);
      if (!_ready) {
        installModel();
      }
    } catch (e) {
      debugPrint('[Gemma] Init: $e');
      _ready = false;
    }
  }

  Future<void> installModel() async {
    if (_downloading || _ready) return;

    _downloading = true;
    _progress = 0;
    _onStatusChanged.add(null);

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromBundled(
        'gemma3.task',
      ).withProgress((progress) {
        _progress = progress / 100.0;
        _onStatusChanged.add(null);
      }).install();

      _ready = true;
      _downloading = false;
      _onStatusChanged.add(null);
      debugPrint('[Gemma] Model installed successfully');
    } catch (e) {
      debugPrint('[Gemma] Install error: $e');
      _downloading = false;
      _onStatusChanged.add(null);
    }
  }

  Future<InferenceModel> _getModel() async {
    if (_model != null) return _model!;

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (gpuError) {
      debugPrint('[Gemma] GPU failed ($gpuError), trying CPU...');
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
