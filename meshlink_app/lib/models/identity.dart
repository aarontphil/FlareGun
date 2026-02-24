import 'package:uuid/uuid.dart';

/// This device's identity in the mesh network.
class DeviceIdentity {
  final String id;
  String name;
  String emoji;
  final int createdAt;

  static const _emojis = ['🟢', '🔵', '🟣', '🟠', '🔴', '🟡', '🧑‍🚀', '🧑‍🚒', '🧑‍⚕️', '🦺', '📡', '💎'];

  DeviceIdentity({
    String? id,
    String? name,
    String? emoji,
    int? createdAt,
  })  : id = id ?? const Uuid().v4(),
        name = name ?? 'MeshUser-${(id ?? const Uuid().v4()).substring(0, 4)}',
        emoji = emoji ?? _emojis[DateTime.now().millisecond % _emojis.length],
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      id: json['id'] as String?,
      name: json['name'] as String?,
      emoji: json['emoji'] as String?,
      createdAt: json['createdAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'createdAt': createdAt,
      };
}
