import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:intl/intl.dart';

class AppUtils {
  AppUtils._();

  static String getGreeting(BuildContext context, bool isChichewa) {
    final hour = DateTime.now().hour;
    if (isChichewa) {
      if (hour < 12) return 'Mwadzuka bwanji?';
      if (hour < 17) return 'Mwaswera bwanji?';
      return 'Mwaswera bwanji?';
    } else {
      if (hour < 12) return 'Good morning';
      if (hour < 17) return 'Good afternoon';
      return 'Good evening';
    }
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return formatDate(date);
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static String formatConfidence(double confidence) {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // If it starts with 0, remove it and add 265
    if (digits.startsWith('0')) {
      return '+265${digits.substring(1)}';
    } else if (digits.startsWith('265')) {
      return '+265${digits.substring(3)}';
    } else if (digits.startsWith('265')) {
      return '+$digits';
    }
    return phone;
  }

  static bool isValidPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  static bool isValidNationalId(String id) {
    return id.length >= 6 && id.length <= 20;
  }

  static bool isValidPin(String pin) {
    return pin.length == 4 && RegExp(r'^\d{4}$').hasMatch(pin);
  }
}

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _isInitialized = true;
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == 'ny') {
      _currentLanguage = 'ny-TZ'; // Chichewa locale
    } else {
      _currentLanguage = 'en-US';
    }
    await _tts.setLanguage(_currentLanguage);
  }

  Future<void> speak(String text) async {
    await init();
    await stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  void dispose() {
    _tts.stop();
  }
}

class KeyboardUtils {
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  static void showKeyboard(BuildContext context) {
    FocusScope.of(context).requestFocus(FocusNode());
  }
}