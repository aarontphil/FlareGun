import 'package:uuid/uuid.dart';

class MeshMessage {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final String senderEmoji;
  final String priority;
  final int timestamp;
  final Map<String, dynamic>? aiAnalysis;

  MeshMessage({
    String? id,
    required this.text,
    required this.senderId,
    required this.senderName,
    this.senderEmoji = '',
    this.priority = 'normal',
    int? timestamp,
    this.aiAnalysis,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'] as String?,
      text: json['text'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderEmoji: json['senderEmoji'] as String? ?? '',
      priority: json['priority'] as String? ?? 'normal',
      timestamp: json['timestamp'] as int?,
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
    if (aiAnalysis != null) 'aiAnalysis': aiAnalysis,
  };

  String get senderInitial => senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
}
