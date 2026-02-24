import 'package:uuid/uuid.dart';

/// Represents a mesh message sent between devices.
class MeshMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderEmoji;
  final String priority;
  final int timestamp;
  final int ttl;
  final int relayCount;
  final Map<String, dynamic>? aiAnalysis;
  final Map<String, dynamic>? aiPriority;

  MeshMessage({
    String? id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderEmoji = '📱',
    this.priority = 'normal',
    int? timestamp,
    this.ttl = 5,
    this.relayCount = 0,
    this.aiAnalysis,
    this.aiPriority,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmoji: json['senderEmoji'] as String? ?? '📱',
      priority: json['priority'] as String? ?? 'normal',
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ttl: json['ttl'] as int? ?? 5,
      relayCount: json['relayCount'] as int? ?? 0,
      aiAnalysis: json['aiAnalysis'] as Map<String, dynamic>?,
      aiPriority: json['aiPriority'] as Map<String, dynamic>?,
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
        'relayCount': relayCount,
        if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
        if (aiPriority != null) 'aiPriority': aiPriority,
      };
}
