import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String commentId;
  final String authorId;
  final String authorName;
  final String authorDistrict;
  final String text;
  final Timestamp timestamp;
  final List<String> likes;
  final String? replyToName;

  const Comment({
    required this.commentId,
    required this.authorId,
    required this.authorName,
    required this.authorDistrict,
    required this.text,
    required this.timestamp,
    this.likes = const [],
    this.replyToName,
  });

  Comment copyWith({
    String? commentId,
    String? authorId,
    String? authorName,
    String? authorDistrict,
    String? text,
    Timestamp? timestamp,
    List<String>? likes,
    String? replyToName,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorDistrict: authorDistrict ?? this.authorDistrict,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      replyToName: replyToName ?? this.replyToName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'authorId': authorId,
      'authorName': authorName,
      'authorDistrict': authorDistrict,
      'text': text,
      'timestamp': timestamp,
      'likes': likes,
      'replyToName': replyToName,
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    final rawTimestamp = map['timestamp'];
    final timestamp = rawTimestamp is Timestamp
        ? rawTimestamp
        : rawTimestamp is DateTime
        ? Timestamp.fromDate(rawTimestamp)
        : rawTimestamp is String
        ? Timestamp.fromDate(DateTime.tryParse(rawTimestamp) ?? DateTime.now())
        : Timestamp.now();

    return Comment(
      commentId: map['commentId']?.toString() ?? map['id']?.toString() ?? '',
      authorId: map['authorId']?.toString() ?? '',
      authorName: map['authorName']?.toString() ?? '',
      authorDistrict: map['authorDistrict']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      timestamp: timestamp,
      likes: List<String>.from(map['likes'] ?? const <String>[]),
      replyToName: map['replyToName']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    commentId,
    authorId,
    authorName,
    authorDistrict,
    text,
    timestamp,
    likes,
    replyToName,
  ];
}
