import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  final _x25519 = X25519();
  final _aes = AesGcm.with256bits();
  final _hkdf = Hkdf(hmac: Hmac(Sha256()), outputLength: 32);
  final _sha256 = Sha256();
  final _storage = const FlutterSecureStorage();

  SimpleKeyPairData? _keyPair;
  SimplePublicKey? _publicKey;
  final Map<String, SecretKey> _sharedKeys = {};
  final Map<String, int> _ratchetCounters = {};

  String get publicKeyBase64 =>
      _publicKey != null ? base64Encode(_publicKey!.bytes) : '';

  bool hasSharedKey(String peerId) => _sharedKeys.containsKey(peerId);


  String getSafetyNumber(String peerId) {
    final peerPubB64 = _peerPublicKeysB64[peerId];
    if (peerPubB64 == null || _publicKey == null) return '------';

    final myB64 = publicKeyBase64;
    final keys = [myB64, peerPubB64]..sort();
    final combined = utf8.encode(keys.join(':'));

    int h = 0x811c9dc5;
    for (final b in combined) {
      h = ((h ^ b) * 0x01000193) & 0xFFFFFFFF;
    }
    final num = h % 1000000;
    return num.toString().padLeft(6, '0');
  }

  final Map<String, String> _peerPublicKeysB64 = {};

  Future<void> init() async {
    try {
      final privB64 = await _storage.read(key: 'fg_private_key');
      final pubB64 = await _storage.read(key: 'fg_public_key');

      if (privB64 != null && pubB64 != null) {
        final privBytes = List<int>.from(base64Decode(privB64));
        final pubBytes = List<int>.from(base64Decode(pubB64));
        _publicKey = SimplePublicKey(pubBytes, type: KeyPairType.x25519);
        _keyPair = SimpleKeyPairData(
          privBytes,
          publicKey: _publicKey!,
          type: KeyPairType.x25519,
        );
      } else {
        final kp = await _x25519.newKeyPair();
        _keyPair = await kp.extract();
        _publicKey = await kp.extractPublicKey() as SimplePublicKey;
        await _storage.write(
          key: 'fg_private_key',
          value: base64Encode(Uint8List.fromList(_keyPair!.bytes)),
        );
        await _storage.write(
          key: 'fg_public_key',
          value: base64Encode(Uint8List.fromList(_publicKey!.bytes)),
        );
      }

      final peerKeysJson = await _storage.read(key: 'fg_peer_keys');
      if (peerKeysJson != null) {
        final map = Map<String, String>.from(jsonDecode(peerKeysJson) as Map);
        for (final entry in map.entries) {
          _peerPublicKeysB64[entry.key] = entry.value;
          final pubBytes = base64Decode(entry.value);
          final peerPub = SimplePublicKey(List<int>.from(pubBytes), type: KeyPairType.x25519);
          await _deriveSharedKey(entry.key, peerPub);
        }
      }

      final countersJson = await _storage.read(key: 'fg_ratchet_counters');
      if (countersJson != null) {
        final map = Map<String, dynamic>.from(jsonDecode(countersJson) as Map);
        for (final entry in map.entries) {
          _ratchetCounters[entry.key] = entry.value as int;
        }
      }

      debugPrint('[Crypto] Initialized (secure storage). Key: ${publicKeyBase64.substring(0, 8)}...');
    } catch (e) {
      debugPrint('[Crypto] Init error: $e');
    }
  }

  Future<void> handlePeerPublicKey(String peerId, String base64PubKey) async {
    _peerPublicKeysB64[peerId] = base64PubKey;
    final pubBytes = base64Decode(base64PubKey);
    final peerPub = SimplePublicKey(List<int>.from(pubBytes), type: KeyPairType.x25519);
    await _deriveSharedKey(peerId, peerPub);

    await _storage.write(
      key: 'fg_peer_keys',
      value: jsonEncode(_peerPublicKeysB64),
    );

    debugPrint('[Crypto] Shared key derived for peer: $peerId');
  }

  Future<void> _deriveSharedKey(String peerId, SimplePublicKey peerPub) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: _keyPair!,
      remotePublicKey: peerPub,
    );
    final sharedBytes = await shared.extractBytes();
    _sharedKeys[peerId] = SecretKey(sharedBytes);
    _ratchetCounters.putIfAbsent(peerId, () => 0);
  }


  Future<SecretKey> _ratchetKey(String peerId) async {
    final baseKey = _sharedKeys[peerId];
    if (baseKey == null) throw StateError('No shared key for $peerId');

    final counter = _ratchetCounters[peerId] ?? 0;
    final info = utf8.encode('flaregun-ratchet-$counter');

    final derived = await _hkdf.deriveKey(
      secretKey: baseKey,
      nonce: info,
    );

    _ratchetCounters[peerId] = counter + 1;
    await _persistRatchetCounters();
    return derived;
  }

  Future<void> _persistRatchetCounters() async {
    await _storage.write(
      key: 'fg_ratchet_counters',
      value: jsonEncode(_ratchetCounters),
    );
  }

  Future<String> encrypt(String plaintext, String peerId) async {
    final key = _sharedKeys[peerId];
    if (key == null) return plaintext;

    try {
      final msgKey = await _ratchetKey(peerId);
      final counter = (_ratchetCounters[peerId] ?? 1) - 1;

      final secretBox = await _aes.encrypt(
        utf8.encode(plaintext),
        secretKey: msgKey,
      );

      final nonce = Uint8List.fromList(secretBox.nonce);
      final mac = Uint8List.fromList(secretBox.mac.bytes);
      final ct = Uint8List.fromList(secretBox.cipherText);
      final counterBytes = Uint8List(4)..buffer.asByteData().setInt32(0, counter);


      final combined = Uint8List(4 + nonce.length + mac.length + ct.length);
      combined.setRange(0, 4, counterBytes);
      combined.setRange(4, 4 + nonce.length, nonce);
      combined.setRange(4 + nonce.length, 4 + nonce.length + mac.length, mac);
      combined.setRange(4 + nonce.length + mac.length, combined.length, ct);

      return base64Encode(combined);
    } catch (e) {
      debugPrint('[Crypto] Encrypt error: $e');
      return plaintext;
    }
  }

  Future<String> decrypt(String ciphertext, String peerId) async {
    final baseKey = _sharedKeys[peerId];
    if (baseKey == null) return ciphertext;

    try {
      final combined = base64Decode(ciphertext);
      if (combined.length < 36) return ciphertext; // 4+12+16 minimum

      final counter = ByteData.sublistView(Uint8List.fromList(combined.sublist(0, 4))).getInt32(0);
      final nonce = combined.sublist(4, 16);
      final mac = Mac(combined.sublist(16, 32));
      final ct = combined.sublist(32);


      final info = utf8.encode('flaregun-ratchet-$counter');
      final msgKey = await _hkdf.deriveKey(
        secretKey: baseKey,
        nonce: info,
      );

      final secretBox = SecretBox(ct, nonce: nonce, mac: mac);
      final plainBytes = await _aes.decrypt(secretBox, secretKey: msgKey);


      final ourCounter = _ratchetCounters[peerId] ?? 0;
      if (counter >= ourCounter) {
        _ratchetCounters[peerId] = counter + 1;
        await _persistRatchetCounters();
      }

      return utf8.decode(plainBytes);
    } catch (e) {
      debugPrint('[Crypto] Decrypt error: $e');
      return ciphertext;
    }
  }
}
