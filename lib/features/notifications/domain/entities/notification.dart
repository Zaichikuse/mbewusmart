import 'package:equatable/equatable.dart';

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? senderId;
  final String? senderName;
  final String? receiverId;
  final String? epa;
  final String? district;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.senderId,
    this.senderName,
    this.receiverId,
    this.epa,
    this.district,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    String? senderId,
    String? senderName,
    String? receiverId,
    String? epa,
    String? district,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      receiverId: receiverId ?? this.receiverId,
      epa: epa ?? this.epa,
      district: district ?? this.district,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'epa': epa,
      'district': district,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      senderId: map['senderId'],
      senderName: map['senderName'],
      receiverId: map['receiverId'],
      epa: map['epa'],
      district: map['district'],
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory AppNotification.fromFirestore(Map<String, dynamic> map) =>
      AppNotification.fromMap(map);

  @override
  List<Object?> get props => [
    id, title, body, type, senderId, senderName, receiverId,
    epa, district, timestamp, isRead, metadata
  ];
}

enum NotificationType {
  diseaseAlert,
  messageReceived,
  reportUpdate,
  systemAlert,
  locationAlert,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.diseaseAlert:
        return 'Disease Alert';
      case NotificationType.messageReceived:
        return 'Message';
      case NotificationType.reportUpdate:
        return 'Report Update';
      case NotificationType.systemAlert:
        return 'System';
      case NotificationType.locationAlert:
        return 'Location';
    }
  }
}
