import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GemmaService {
  bool _ready = false;
  bool get isReady => _ready;
  bool get isDownloading => false;
  double get downloadProgress => 1.0;

  String _ollamaHost = '';

  final _onStatusChanged = StreamController<void>.broadcast();
  Stream<void> get onStatusChanged => _onStatusChanged.stream;

  static const _systemPrompt =
      'You are FlareGun AI, a disaster relief assistant. '
      'Give short, clear, actionable answers about survival, first aid, '
      'earthquake/flood/fire safety, finding shelter, and staying safe. '
      'Keep responses under 150 words.';

  Future<void> init() async {
    await _discoverOllama();
  }

  Future<void> _discoverOllama() async {
    final candidates = <String>[];

    candidates.add('http://172.20.10.3:11434');
    candidates.add('http://10.0.2.2:11434');

    try {
      final info = await NetworkInterface.list();
      for (final iface in info) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final parts = addr.address.split('.');
            parts[3] = '1';
            candidates.add('http://${parts.join('.')}:11434');
            
            for (int i = 2; i <= 10; i++) {
              parts[3] = '$i';
              candidates.add('http://${parts.join('.')}:11434');
            }
          }
        }
      }
    } catch (_) {}

    candidates.add('http://192.168.1.1:11434');
    candidates.add('http://192.168.0.1:11434');
    candidates.add('http://192.168.1.2:11434');
    candidates.add('http://192.168.0.2:11434');
    candidates.add('http://192.168.1.100:11434');
    candidates.add('http://192.168.0.100:11434');
    candidates.add('http://localhost:11434');
    candidates.add('http://127.0.0.1:11434');

    for (final host in candidates) {
      try {
        final resp = await http.get(
          Uri.parse('$host/api/tags'),
        ).timeout(const Duration(seconds: 2));

        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final models = data['models'] as List? ?? [];
          if (models.isNotEmpty) {
            _ollamaHost = host;
            _ready = true;
            _onStatusChanged.add(null);
            debugPrint('[AI] Connected to Ollama at $host');
            return;
          }
        }
      } catch (_) {
        continue;
      }
    }

    debugPrint('[AI] No Ollama server found');
    _ready = false;
    _onStatusChanged.add(null);
  }

  void setHost(String host) {
    _ollamaHost = host.endsWith(':11434') ? host : '$host:11434';
    if (!_ollamaHost.startsWith('http')) {
      _ollamaHost = 'http://$_ollamaHost';
    }
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      final resp = await http.get(
        Uri.parse('$_ollamaHost/api/tags'),
      ).timeout(const Duration(seconds: 3));
      _ready = resp.statusCode == 200;
    } catch (_) {
      _ready = false;
    }
    _onStatusChanged.add(null);
  }

  Future<void> installModel() async {
    await _discoverOllama();
  }

  Stream<String> chatStream(String query) async* {
    if (!_ready || _ollamaHost.isEmpty) {
      throw Exception('Ollama not connected');
    }

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_ollamaHost/api/generate'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': 'gemma2:2b',
        'prompt': '$_systemPrompt\n\nUser: $query\n\nAssistant:',
        'stream': true,
        'options': {
          'num_predict': 256,
          'temperature': 0.7,
        },
      });

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        throw Exception('Ollama error: ${response.statusCode}');
      }

      await for (final chunk in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (chunk.trim().isEmpty) continue;
        try {
          final data = jsonDecode(chunk);
          final token = data['response'] as String? ?? '';
          if (token.isNotEmpty) {
            yield token;
          }
          if (data['done'] == true) break;
        } catch (_) {
          continue;
        }
      }

      client.close();
    } catch (e) {
      debugPrint('[AI] Chat error: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _onStatusChanged.close();
  }
}
