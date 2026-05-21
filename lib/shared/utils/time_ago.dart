import 'package:cloud_firestore/cloud_firestore.dart';

String timeAgoFromTimestamp(dynamic timestamp) {
  final dateTime = _toDateTime(timestamp);
  if (dateTime == null) return 'Unknown';

  final difference = DateTime.now().difference(dateTime);

  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} d ago';
  }

  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${dateTime.day} ${monthNames[dateTime.month - 1]}';
}

DateTime? _toDateTime(dynamic timestamp) {
  if (timestamp is Timestamp) return timestamp.toDate();
  if (timestamp is DateTime) return timestamp;
  if (timestamp is String) return DateTime.tryParse(timestamp);
  return null;
}
