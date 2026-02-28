import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CryptoService {
  final _x25519 = X25519();
  final _aes = AesGcm.with256bits();

  SimpleKeyPairData? _keyPair;
  SimplePublicKey? _publicKey;
  final Map<String, SecretKey> _sharedKeys = {};

  String get publicKeyBase64 => _publicKey != null
      ? base64Encode(_publicKey!.bytes)
      : '';

  bool hasSharedKey(String peerId) => _sharedKeys.containsKey(peerId);

  Future<void> init() async {
    final box = await Hive.openBox('crypto');
    final stored = box.get('privateKey');
    final storedPub = box.get('publicKey');

    if (stored != null && storedPub != null) {
      final privBytes = List<int>.from(base64Decode(stored as String));
      final pubBytes = List<int>.from(base64Decode(storedPub as String));
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
      await box.put('privateKey', base64Encode(Uint8List.fromList(_keyPair!.bytes)));
      await box.put('publicKey', base64Encode(Uint8List.fromList(_publicKey!.bytes)));
    }

    final peerKeys = box.get('peerKeys');
    if (peerKeys != null) {
      final map = Map<String, String>.from(peerKeys as Map);
      for (final entry in map.entries) {
        final pubBytes = base64Decode(entry.value);
        final peerPub = SimplePublicKey(List<int>.from(pubBytes), type: KeyPairType.x25519);
        await _deriveSharedKey(entry.key, peerPub);
      }
    }

    debugPrint('[Crypto] Initialized. Public key: ${publicKeyBase64.substring(0, 8)}...');
  }

  Future<void> handlePeerPublicKey(String peerId, String base64PubKey) async {
    final pubBytes = base64Decode(base64PubKey);
    final peerPub = SimplePublicKey(List<int>.from(pubBytes), type: KeyPairType.x25519);
    await _deriveSharedKey(peerId, peerPub);

    final box = await Hive.openBox('crypto');
    final existing = Map<String, String>.from(box.get('peerKeys', defaultValue: {}) as Map);
    existing[peerId] = base64PubKey;
    await box.put('peerKeys', existing);

    debugPrint('[Crypto] Shared key derived for peer: $peerId');
  }

  Future<void> _deriveSharedKey(String peerId, SimplePublicKey peerPub) async {
    final shared = await _x25519.sharedSecretKey(
      keyPair: _keyPair!,
      remotePublicKey: peerPub,
    );
    final sharedBytes = await shared.extractBytes();
    _sharedKeys[peerId] = SecretKey(sharedBytes);
  }

  Future<String> encrypt(String plaintext, String peerId) async {
    final key = _sharedKeys[peerId];
    if (key == null) return plaintext;

    try {
      final secretBox = await _aes.encrypt(
        utf8.encode(plaintext),
        secretKey: key,
      );
      final nonce = Uint8List.fromList(secretBox.nonce);
      final mac = Uint8List.fromList(secretBox.mac.bytes);
      final ct = Uint8List.fromList(secretBox.cipherText);
      final combined = Uint8List(nonce.length + mac.length + ct.length);
      combined.setRange(0, nonce.length, nonce);
      combined.setRange(nonce.length, nonce.length + mac.length, mac);
      combined.setRange(nonce.length + mac.length, combined.length, ct);
      return base64Encode(combined);
    } catch (e) {
      debugPrint('[Crypto] Encrypt error: $e');
      return plaintext;
    }
  }

  Future<String> decrypt(String ciphertext, String peerId) async {
    final key = _sharedKeys[peerId];
    if (key == null) return ciphertext;

    try {
      final combined = base64Decode(ciphertext);
      const nonceLen = 12;
      const macLen = 16;

      final nonce = combined.sublist(0, nonceLen);
      final mac = Mac(combined.sublist(nonceLen, nonceLen + macLen));
      final ct = combined.sublist(nonceLen + macLen);

      final secretBox = SecretBox(ct, nonce: nonce, mac: mac);
      final plainBytes = await _aes.decrypt(secretBox, secretKey: key);
      return utf8.decode(plainBytes);
    } catch (e) {
      debugPrint('[Crypto] Decrypt error: $e');
      return ciphertext;
    }
  }
}
