import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? imageUrl;
  final String? replyToMessageId;
  final String? diseaseReportId;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.imageUrl,
    this.replyToMessageId,
    this.diseaseReportId,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    String? imageUrl,
    String? replyToMessageId,
    String? diseaseReportId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      diseaseReportId: diseaseReportId ?? this.diseaseReportId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'status': status.name,
      'imageUrl': imageUrl,
      'replyToMessageId': replyToMessageId,
      'diseaseReportId': diseaseReportId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      imageUrl: map['imageUrl'],
      replyToMessageId: map['replyToMessageId'],
      diseaseReportId: map['diseaseReportId'],
    );
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory Message.fromFirestore(Map<String, dynamic> map) => Message.fromMap(map);

  @override
  List<Object?> get props => [
    id, conversationId, senderId, receiverId, content, 
    timestamp, type, status, imageUrl, replyToMessageId, diseaseReportId
  ];
}

enum MessageType {
  text,
  image,
  report,
}

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
