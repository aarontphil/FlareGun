import 'package:uuid/uuid.dart';

enum MessageStatus { sending, sent, delivered, read }

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
  final String msgType;
  MessageStatus status;
  bool isRead;
  bool encrypted;
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
    this.msgType = 'message',
    this.status = MessageStatus.sending,
    this.isRead = false,
    this.encrypted = false,
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
      msgType: json['msgType'] as String? ?? 'message',
      status: _parseStatus(json['status'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      encrypted: json['encrypted'] as bool? ?? false,
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
    'msgType': msgType,
    'status': status.name,
    'isRead': isRead,
    'encrypted': encrypted,
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
      msgType: msgType,
      status: status,
      aiAnalysis: aiAnalysis,
    );
  }

  static MeshMessage receipt(String originalMsgId, String senderId, String senderName) {
    return MeshMessage(
      text: originalMsgId,
      senderId: senderId,
      senderName: senderName,
      msgType: 'receipt',
      ttl: 7,
    );
  }

  bool get isReceipt => msgType == 'receipt';
  bool get canForward => ttl > 0;
  String get senderInitial => senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

  static MessageStatus _parseStatus(String? s) {
    switch (s) {
      case 'sent': return MessageStatus.sent;
      case 'delivered': return MessageStatus.delivered;
      case 'read': return MessageStatus.read;
      default: return MessageStatus.sending;
    }
  }
}
