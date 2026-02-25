class Peer {
  final String deviceId;
  final String name;
  final bool connected;
  final int lastSeen;
  final int messageCount;

  Peer({
    required this.deviceId,
    required this.name,
    this.connected = false,
    int? lastSeen,
    this.messageCount = 0,
  }) : lastSeen = lastSeen ?? DateTime.now().millisecondsSinceEpoch;

  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      deviceId: json['deviceId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      connected: json['connected'] as bool? ?? true,
      lastSeen: _parseTimestamp(json['lastSeen'] ?? json['joinedAt']),
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }

  Peer copyWith({bool? connected, int? messageCount, int? lastSeen}) {
    return Peer(
      deviceId: deviceId,
      name: name,
      connected: connected ?? this.connected,
      lastSeen: lastSeen ?? this.lastSeen,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  String get lastSeenFormatted {
    final diff = DateTime.now().millisecondsSinceEpoch - lastSeen;
    if (diff < 60000) return 'just now';
    if (diff < 3600000) return '${(diff / 60000).floor()}m ago';
    if (diff < 86400000) return '${(diff / 3600000).floor()}h ago';
    return '${(diff / 86400000).floor()}d ago';
  }
}

int _parseTimestamp(dynamic value) {
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now().millisecondsSinceEpoch;
}
