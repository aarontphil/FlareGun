import 'dart:async';
import 'package:flutter/foundation.dart';

class GemmaService {
  bool _ready = false;
  bool get isReady => _ready;
  bool get isDownloading => _downloading;
  double get downloadProgress => _progress;

  bool _downloading = false;
  double _progress = 0;

  final _onStatusChanged = StreamController<void>.broadcast();
  Stream<void> get onStatusChanged => _onStatusChanged.stream;

  Future<void> init() async {
    try {
      final gemmaLib = await _importGemma();
      if (gemmaLib != null) {
        _ready = true;
        _onStatusChanged.add(null);
      }
    } catch (e) {
      debugPrint('[Gemma] Init: $e');
      _ready = false;
    }
  }

  Future<void> installModel() async {
    if (_downloading) return;
    _downloading = true;
    _progress = 0;
    _onStatusChanged.add(null);

    try {
      final dynamic flutterGemma = await _importGemma();
      if (flutterGemma == null) throw Exception('Gemma not available');

      _progress = 0.5;
      _onStatusChanged.add(null);

      await Future.delayed(const Duration(seconds: 2));

      _progress = 1.0;
      _ready = true;
      _downloading = false;
      _onStatusChanged.add(null);
    } catch (e) {
      debugPrint('[Gemma] Install: $e');
      _downloading = false;
      _onStatusChanged.add(null);
    }
  }

  Future<dynamic> _importGemma() async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      return null;
    } catch (_) {
      return null;
    }
  }

  Stream<String> chatStream(String query) async* {
    throw UnimplementedError('Gemma not available on this device');
  }

  Future<void> dispose() async {
    await _onStatusChanged.close();
  }
}
