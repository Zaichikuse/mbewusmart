import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../features/diagnosis/domain/entities/diagnosis_result.dart';
import '../../features/diagnosis/domain/entities/crop_type.dart';
import '../../features/location/domain/entities/agro_dealer.dart';
import '../../features/location/domain/entities/extension_officer.dart';

class AiChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;
  final String languageCode;
  final String? diagnosisId;

  const AiChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
    required this.languageCode,
    this.diagnosisId,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'languageCode': languageCode,
      'diagnosisId': diagnosisId,
    };
  }

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      role: map['role'] as String? ?? 'assistant',
      text: map['text'] as String? ?? '',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      languageCode: map['languageCode'] as String? ?? 'en',
      diagnosisId: map['diagnosisId'] as String?,
    );
  }
}

class AiAssistantService {
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  final Box cacheBox;
  String _currentUiContext = 'General';

  AiAssistantService({required this.cacheBox});

  String _historyKeyForLanguage(String languageCode, {String? userId}) {
    final scopedUserId = (userId == null || userId.trim().isEmpty)
        ? 'guest'
        : userId.trim();
    return 'ai_chat_history_${scopedUserId}_$languageCode';
  }

  String getLocalizedHeading(bool isChichewa) {
    return isChichewa ? 'AI Wothandiza' : 'AI Assistant';
  }

  void setCurrentUiContext(String context) {
    _currentUiContext = context;
  }

  String get currentUiContext => _currentUiContext;

  List<AiChatMessage> loadHistory(String languageCode, {String? userId}) {
    final dynamic raw = cacheBox.get(
      _historyKeyForLanguage(languageCode, userId: userId),
    );
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((e) => AiChatMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveHistory(
    List<AiChatMessage> messages,
    String languageCode, {
    String? userId,
  }) async {
    final data = messages.map((m) => m.toMap()).toList();
    await cacheBox.put(
      _historyKeyForLanguage(languageCode, userId: userId),
      data,
    );
  }

  String buildPersonalizedGreeting({
    required bool isChichewa,
    required String? userName,
    required int previousMessages,
    String? latestDiagnosisName,
  }) {
    final safeName = (userName == null || userName.trim().isEmpty)
        ? (isChichewa ? 'Mlimi' : 'Farmer')
        : userName.trim().split(' ').first;

    if (isChichewa) {
      final diagnosisLine = latestDiagnosisName == null
          ? ''
          : ' Zotsatira zanu zaposachedwa: $latestDiagnosisName.';
      return 'Moni $safeName. Ndine AI wanu waulimi. Ndikukumbukira mauthenga $previousMessages am\'mbuyo.$diagnosisLine';
    }

    final diagnosisLine = latestDiagnosisName == null
        ? ''
        : ' Your latest diagnosis is $latestDiagnosisName.';
    return 'Hello $safeName. I am your farming AI assistant. I remember $previousMessages earlier messages.$diagnosisLine';
  }

  bool _isAutomationRequest(String prompt) {
    final p = prompt.toLowerCase();
    const patterns = [
      'nearby help',
      'near help',
      'closest help',
      'agro dealer',
      'agrodealer',
      'extension officer',
      'locate dealer',
      'where to buy',
      'wogulitsa',
      'thandizo',
      'pafupi',
      'afesa',
      'agro',
    ];

    return patterns.any(p.contains);
  }

  String _buildAutomationReply({
    required bool isChichewa,
    required String? locationName,
    required ExtensionOfficer? nearestOfficer,
    required AgroDealer? nearestDealer,
  }) {
    final buffer = StringBuffer();

    if (isChichewa) {
      buffer.writeln('Nawa malo othandiza omwe ali pafupi ndi inu:');
      if (locationName != null && locationName.isNotEmpty) {
        buffer.writeln('- Malo anu: $locationName');
      }

      if (nearestDealer != null) {
        buffer.writeln(
          '- Agro-dealer: ${nearestDealer.name}, ${nearestDealer.district}, foni: ${nearestDealer.phone}',
        );
      } else {
        buffer.writeln('- Palibe agro-dealer wapafupi amene wapezeka pano.');
      }

      if (nearestOfficer != null) {
        buffer.writeln(
          '- Afesa Officer: ${nearestOfficer.name}, ${nearestOfficer.district}, foni: ${nearestOfficer.phone}',
        );
      } else {
        buffer.writeln('- Palibe Afesa Officer wapafupi amene wapezeka pano.');
      }

      buffer.writeln(
        'Mungagwiritse ntchito ma nambala awa kuti mulumikizane mwachangu.',
      );
    } else {
      buffer.writeln('Here is nearby support for your location:');
      if (locationName != null && locationName.isNotEmpty) {
        buffer.writeln('- Your location: $locationName');
      }

      if (nearestDealer != null) {
        buffer.writeln(
          '- Agro-dealer: ${nearestDealer.name}, ${nearestDealer.district}, phone: ${nearestDealer.phone}',
        );
      } else {
        buffer.writeln('- No nearby agro-dealer found in local data.');
      }

      if (nearestOfficer != null) {
        buffer.writeln(
          '- Extension Officer: ${nearestOfficer.name}, ${nearestOfficer.district}, phone: ${nearestOfficer.phone}',
        );
      } else {
        buffer.writeln('- No nearby extension officer found in local data.');
      }

      buffer.writeln('Use these contacts to get help quickly.');
    }

    return buffer.toString().trim();
  }

  Future<String> askQuestion({
    required String prompt,
    required bool isChichewa,
    required List<AiChatMessage> history,
    DiagnosisResult? diagnosis,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
    String? locationName,
    String? pageContext,
  }) async {
    if (_isAutomationRequest(prompt)) {
      return _buildAutomationReply(
        isChichewa: isChichewa,
        locationName: locationName,
        nearestOfficer: nearestOfficer,
        nearestDealer: nearestDealer,
      );
    }

    if (_geminiApiKey.isEmpty) {
      return isChichewa
          ? 'GEMINI_API_KEY sinalembedwe. Yambitsani app ndi --dart-define=GEMINI_API_KEY=your_key kuti AI iyankhe mokwanira.'
          : 'GEMINI_API_KEY is not configured. Start the app with --dart-define=GEMINI_API_KEY=your_key to enable full AI answers.';
    }

    final recentHistory = history.length > 8
        ? history.sublist(history.length - 8)
        : history;
    final historyText = recentHistory
        .map((m) => '${m.role.toUpperCase()}: ${m.text}')
        .join('\n');

    final diagnosisContext = diagnosis == null
        ? 'No diagnosis selected.'
        : '''
Diagnosis context:
- Crop: ${diagnosis.cropType.displayName}
- Result: ${diagnosis.diagnosisName}
- Confidence: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%
- Severity: ${diagnosis.severity.displayName}
- Treatment: ${diagnosis.treatment ?? 'N/A'}
- Prevention: ${diagnosis.prevention ?? 'N/A'}
''';

    final languageInstruction = isChichewa
        ? 'Reply in Chichewa, simple farmer-friendly style. Keep answers practical and short.'
        : 'Reply in English, simple farmer-friendly style. Keep answers practical and short.';

    final supportContext =
        '''
Nearby support:
- Location: ${locationName ?? 'Unknown'}
- Agro-dealer: ${nearestDealer?.name ?? 'Unknown'} (${nearestDealer?.phone ?? 'No phone'})
- Extension officer: ${nearestOfficer?.name ?? 'Unknown'} (${nearestOfficer?.phone ?? 'No phone'})
''';

    final uiContext = pageContext ?? _currentUiContext;

    final userPrompt =
        '''
You are an agricultural assistant for Malawi farmers.
$languageInstruction
If asked about nearby help or agro-dealers, use the support context provided.
Give safe farming guidance only.

$diagnosisContext
$supportContext
Current app context:
- Screen context: $uiContext
Conversation history:
$historyText

User question:
$prompt
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': userPrompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 450},
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode >= 400) {
      return isChichewa
          ? 'AI yalephera kuyankha pano. Yesani kachiwiri pangono.'
          : 'AI could not answer right now. Please try again shortly.';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = (json['candidates'] as List<dynamic>? ?? const []);
    if (candidates.isEmpty) {
      return isChichewa
          ? 'Palibe yankho la AI pakali pano. Yesaninso.'
          : 'No AI response was returned. Please try again.';
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List<dynamic>? ?? const []);
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join('\n')
        .trim();

    if (text.isEmpty) {
      return isChichewa
          ? 'AI sinapereke yankho lomveka.'
          : 'AI did not return a usable response.';
    }

    return text;
  }
}
