import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ImageEncoder {
  static Future<String> encodeForFirestore(
    Uint8List bytes, {
    int maxWidth = 640,
    int quality = 75,
  }) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return base64Encode(bytes);
    }

    final resized = decoded.width > maxWidth
        ? img.copyResize(decoded, width: maxWidth)
        : decoded;
    final compressed = img.encodeJpg(resized, quality: quality);
    return base64Encode(compressed);
  }

  static Uint8List? decodeFromFirestore(String? encoded) {
    final value = encoded?.trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
