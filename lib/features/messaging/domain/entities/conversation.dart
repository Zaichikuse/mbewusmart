import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user.dart';

class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final UserRole targetRole;
  final String? targetEpa;
  final String? targetDistrict;
  final String? lastMessageContent;
  final DateTime? lastMessageTimestamp;
  final int unreadCount;
  final DateTime createdAt;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.targetRole,
    this.targetEpa,
    this.targetDistrict,
    this.lastMessageContent,
    this.lastMessageTimestamp,
    this.unreadCount = 0,
    required this.createdAt,
  });

  Conversation copyWith({
    String? id,
    List<String>? participantIds,
    UserRole? targetRole,
    String? targetEpa,
    String? targetDistrict,
    String? lastMessageContent,
    DateTime? lastMessageTimestamp,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      targetRole: targetRole ?? this.targetRole,
      targetEpa: targetEpa ?? this.targetEpa,
      targetDistrict: targetDistrict ?? this.targetDistrict,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTimestamp: lastMessageTimestamp ?? this.lastMessageTimestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participantIds': participantIds,
      'targetRole': targetRole.toStorageString(),
      'targetEpa': targetEpa,
      'targetDistrict': targetDistrict,
      'lastMessageContent': lastMessageContent,
      'lastMessageTimestamp': lastMessageTimestamp?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      targetRole: UserRoleExtension.fromString(map['targetRole'] ?? 'farmer'),
      targetEpa: map['targetEpa'],
      targetDistrict: map['targetDistrict'],
      lastMessageContent: map['lastMessageContent'],
      lastMessageTimestamp: map['lastMessageTimestamp'] != null
          ? DateTime.tryParse(map['lastMessageTimestamp'])
          : null,
      unreadCount: map['unreadCount'] ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => toMap();

  factory Conversation.fromFirestore(Map<String, dynamic> map) => 
      Conversation.fromMap(map);

  String getDisplayName(UserRole currentUserRole) {
    switch (targetRole) {
      case UserRole.extensionOfficer:
        return currentUserRole == UserRole.farmer 
            ? 'Extension Officer' 
            : 'Farmer';
      case UserRole.agricultureManager:
        return 'Agriculture Manager';
      case UserRole.agroDealer:
        return 'Agro-Dealer';
      case UserRole.farmer:
        return 'Farmer';
    }
  }

  @override
  List<Object?> get props => [
    id, participantIds, targetRole, targetEpa, targetDistrict,
    lastMessageContent, lastMessageTimestamp, unreadCount, createdAt
  ];
}
