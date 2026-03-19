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
        installModel();
      }
    } catch (e) {
      debugPrint('[Gemma] Init error: $e');
      _lastError = e.toString();
      _ready = false;
    }
  }

  Future<void> installModel() async {
    if (_downloading || _ready) return;

    _downloading = true;
    _progress = 0;
    _lastError = null;
    _onStatusChanged.add(null);

    try {
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
      ).fromAsset(
        'assets/model.task',
      ).withProgress((int percent) {
        _progress = percent / 100.0;
        _onStatusChanged.add(null);
      }).install();

      _ready = true;
      _downloading = false;
      _onStatusChanged.add(null);
    } catch (e) {
      debugPrint('[Gemma] Install error: $e');
      _lastError = e.toString();
      _downloading = false;
      _onStatusChanged.add(null);
    }
  }

  Future<InferenceModel> _getModel() async {
    if (_model != null) return _model!;

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
      );
    } catch (e) {
      debugPrint('[Gemma] GPU failed, trying CPU: $e');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.cpu,
      );
    }
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

      bool hasTokens = false;
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          hasTokens = true;
          yield response.token;
        }
      }

      if (!hasTokens) {
        throw Exception('No response generated');
      }
    } catch (e) {
      debugPrint('[Gemma] Chat error: $e');
      _lastError = e.toString();
      rethrow;
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
      _lastError = e.toString();
      return '';
    }
  }

  Future<void> dispose() async {
    await _model?.close();
    _model = null;
    await _onStatusChanged.close();
  }
}
