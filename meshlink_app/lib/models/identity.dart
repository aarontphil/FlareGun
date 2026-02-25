import 'package:uuid/uuid.dart';

class DeviceIdentity {
  String id;
  String name;
  final int createdAt;

  DeviceIdentity({
    String? id,
    String? name,
    int? createdAt,
  })  : id = id ?? const Uuid().v4(),
        name = name ?? 'User-${(id ?? const Uuid().v4()).substring(0, 4)}',
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory DeviceIdentity.fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      id: json['id'] as String?,
      name: json['name'] as String?,
      createdAt: json['createdAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
  };

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
