import 'package:uuid/uuid.dart';

class MeshMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderEmoji;
  final String priority;
  final int timestamp;
  final int ttl;
  final int hopCount;
  final String originId;
  final Map<String, dynamic>? aiAnalysis;

  MeshMessage({
    String? id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderEmoji = '',
    this.priority = 'normal',
    int? timestamp,
    this.ttl = 7,
    this.hopCount = 0,
    String? originId,
    this.aiAnalysis,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch,
        originId = originId ?? (id ?? const Uuid().v4());

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmoji: json['senderEmoji'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      timestamp: json['timestamp'] as int?,
      ttl: json['ttl'] as int? ?? 7,
      hopCount: json['hopCount'] as int? ?? 0,
      originId: json['originId'] as String?,
      aiAnalysis: json['aiAnalysis'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'senderId': senderId,
    'senderName': senderName,
    'senderEmoji': senderEmoji,
    'priority': priority,
    'timestamp': timestamp,
    'ttl': ttl,
    'hopCount': hopCount,
    'originId': originId,
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
  };

  MeshMessage forwarded() {
    return MeshMessage(
      id: id,
      text: text,
      senderId: senderId,
      senderName: senderName,
      senderEmoji: senderEmoji,
      priority: priority,
      timestamp: timestamp,
      ttl: ttl - 1,
      hopCount: hopCount + 1,
      originId: originId,
      aiAnalysis: aiAnalysis,
    );
  }

  bool get canForward => ttl > 0;

  String get senderInitial => senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
}
