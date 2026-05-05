import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class FcmNotificationService {
  static const _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  String get _serverKey {
    final raw = dotenv.env['FCM_SERVER_KEY'] ?? '';
    return raw.trim();
  }

  Future<void> sendToTokens({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final key = _serverKey;
    if (key.isEmpty || tokens.isEmpty) return;

    for (final token in tokens.toSet()) {
      await http.post(
        Uri.parse(_fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$key',
        },
        body: jsonEncode({
          'to': token,
          'priority': 'high',
          'notification': {'title': title, 'body': body},
          'data': data ?? <String, dynamic>{},
        }),
      );
    }
  }
}
