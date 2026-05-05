import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
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
  final Box cacheBox;
  String _currentUiContext = 'General';

  AiAssistantService({required this.cacheBox});

  String _sanitizeApiKey(String? raw) {
    if (raw == null) return '';
    var value = raw.trim();

    // Handle .env values wrapped in quotes.
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1).trim();
    }

    return value;
  }

  String get _geminiApiKey {
    final candidates = [
      dotenv.env['GEMINI_API_KEY'],
      dotenv.env['GOOGLE_API_KEY'],
      const String.fromEnvironment('GEMINI_API_KEY'),
      const String.fromEnvironment('GOOGLE_API_KEY'),
    ];

    for (final candidate in candidates) {
      final sanitized = _sanitizeApiKey(candidate);
      if (sanitized.isNotEmpty) {
        return sanitized;
      }
    }

    return '';
  }

  List<String> get _geminiModelCandidates => [
        'gemini-2.0-flash',
        'gemini-2.0-flash-lite',
        'gemini-2.5-flash',
      ];

  String _historyKeyForLanguage(String languageCode, {String? userId}) {
    final scopedUserId = (userId == null || userId.trim().isEmpty)
        ? 'guest'
        : userId.trim();
    return 'ai_chat_history_${scopedUserId}_$languageCode';
  }

  String _historyKeyForDiagnosis(
    String languageCode, {
    String? userId,
    String? diagnosisId,
  }) {
    final baseKey = _historyKeyForLanguage(languageCode, userId: userId);
    if (diagnosisId == null || diagnosisId.trim().isEmpty) {
      return '${baseKey}_general';
    }
    return '${baseKey}_${diagnosisId.trim()}';
  }

  String _supportContextKey({String? userId}) {
    final scopedUserId = (userId == null || userId.trim().isEmpty)
        ? 'guest'
        : userId.trim();
    return '${AppConstants.aiSupportContextKey}_$scopedUserId';
  }

  String getLocalizedHeading(bool isChichewa) {
    return isChichewa ? 'AI Wothandiza' : 'AI Assistant';
  }

  void setCurrentUiContext(String context) {
    _currentUiContext = context;
  }

  String get currentUiContext => _currentUiContext;

  List<AiChatMessage> loadHistory(
    String languageCode, {
    String? userId,
    String? diagnosisId,
  }) {
    final dynamic raw = cacheBox.get(
      _historyKeyForDiagnosis(
        languageCode,
        userId: userId,
        diagnosisId: diagnosisId,
      ),
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
    String? diagnosisId,
  }) async {
    final data = messages.map((m) => m.toMap()).toList();
    await cacheBox.put(
      _historyKeyForDiagnosis(
        languageCode,
        userId: userId,
        diagnosisId: diagnosisId,
      ),
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

  Future<void> saveSupportContext({
    String? userId,
    String? locationName,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
  }) async {
    if ((locationName == null || locationName.trim().isEmpty) &&
        nearestOfficer == null &&
        nearestDealer == null) {
      return;
    }

    await cacheBox.put(_supportContextKey(userId: userId), {
      'locationName': locationName,
      'nearestOfficer': nearestOfficer == null
          ? null
          : {
              'id': nearestOfficer.id,
              'name': nearestOfficer.name,
              'phone': nearestOfficer.phone,
              'district': nearestOfficer.district,
              'area': nearestOfficer.area,
              'latitude': nearestOfficer.latitude,
              'longitude': nearestOfficer.longitude,
              'epa': nearestOfficer.epa,
              'region': nearestOfficer.region,
            },
      'nearestDealer': nearestDealer == null
          ? null
          : {
              'id': nearestDealer.id,
              'name': nearestDealer.name,
              'phone': nearestDealer.phone,
              'district': nearestDealer.district,
              'area': nearestDealer.area,
              'latitude': nearestDealer.latitude,
              'longitude': nearestDealer.longitude,
              'products': nearestDealer.products,
              'epa': nearestDealer.epa,
              'region': nearestDealer.region,
            },
    });
  }

  Map<String, dynamic>? _loadSupportContext({String? userId}) {
    final raw = cacheBox.get(_supportContextKey(userId: userId));
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  ExtensionOfficer? _restoreOfficer(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return ExtensionOfficer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      district: map['district'] as String? ?? '',
      area: map['area'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      epa: map['epa'] as String?,
      region: map['region'] as String?,
    );
  }

  AgroDealer? _restoreDealer(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return AgroDealer(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      district: map['district'] as String? ?? '',
      area: map['area'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      products:
          (map['products'] as List?)?.map((e) => '$e').toList() ?? const [],
      epa: map['epa'] as String?,
      region: map['region'] as String?,
    );
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
      if (nearestDealer == null && nearestOfficer == null) {
        buffer.writeln(
          'Tsekulani chilolezo cha GPS mu phone settings kuti app ipeze agro-dealer ndi Afesa Officer oyandikana nanu.',
        );
      }
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
      if (nearestDealer == null && nearestOfficer == null) {
        buffer.writeln(
          'Enable GPS location permission in your phone settings so the app can find nearby agro-dealers and extension officers.',
        );
      }
    }

    return buffer.toString().trim();
  }

  /// Text injected into Gemini prompts: only non-empty dealer/officer fields;
  /// when both contacts are null, instruct farmer to enable GPS.
  String _buildSupportContextForPrompt({
    required bool isChichewa,
    required String? locationName,
    required ExtensionOfficer? nearestOfficer,
    required AgroDealer? nearestDealer,
  }) {
    final dealer = nearestDealer;
    final officer = nearestOfficer;

    if (dealer == null && officer == null) {
      return isChichewa
          ? 'LOCATION / NEARBY SUPPORT: Palibe thandizo lapafupi lomwe lapezeka. Tsekulani chilolezo cha GPS mu phone settings (Location) kuti app ipeze agro-dealer ndi Afesa Officer oyandikana nanu, ndipo funsani kachiwiri.'
          : 'LOCATION / NEARBY SUPPORT: No nearby contacts are loaded yet. Please enable GPS location permission in your phone settings so the app can find nearby agro-dealers and extension officers, then ask again.';
    }

    final lines = <String>[
      'NEARBY SUPPORT FOR THIS FARMER (use these exact details when the farmer asks about nearby help, dealers, or extension officers):',
    ];

    final loc = (locationName ?? '').trim();
    if (loc.isNotEmpty) {
      lines.add('Location: $loc');
    }

    if (dealer != null) {
      lines.add('Nearest Agro Dealer:');
      final n = dealer.name.trim();
      final p = dealer.phone.trim();
      final d = dealer.district.trim();
      if (n.isNotEmpty) lines.add('- Name: $n');
      if (p.isNotEmpty) lines.add('- Phone: $p');
      if (d.isNotEmpty) lines.add('- District: $d');
    }

    if (officer != null) {
      lines.add('Nearest Extension Officer:');
      final n = officer.name.trim();
      final p = officer.phone.trim();
      final d = officer.district.trim();
      if (n.isNotEmpty) lines.add('- Name: $n');
      if (p.isNotEmpty) lines.add('- Phone: $p');
      if (d.isNotEmpty) lines.add('- District: $d');
    }

    lines.add('');
    lines.add(
      'When the farmer asks about nearby help, agro-dealers, extension officers, or buying inputs locally, you MUST include the exact names, phone numbers, and districts from above—never invent contacts and never give a vague reply if those lines are present.',
    );

    return lines.join('\n');
  }

  String _buildLocalAssistantFallback({
    required bool isChichewa,
    required String prompt,
    DiagnosisResult? diagnosis,
    String? locationName,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
    String? reason,
  }) {
    final hasDiagnosis = diagnosis != null;
    const offlineMessage = 'Connection failed. Check your internet.';

    if (isChichewa) {
      final parts = <String>[offlineMessage];

      if (hasDiagnosis) {
        final d = diagnosis;
        parts.add(
          'Zotsatira zaposachedwa: ${d.diagnosisNameChichewa} (${(d.confidence * 100).toStringAsFixed(0)}% confidence).',
        );
        if ((d.treatment ?? '').trim().isNotEmpty) {
          parts.add('Chithandizo: ${d.treatment}.');
        }
        if ((d.prevention ?? '').trim().isNotEmpty) {
          parts.add('Kupewa: ${d.prevention}.');
        }
      } else {
        parts.add(
          'Sindingaone diagnosis yanu pano, chonde yambani ndi crop scan kenako funsani kachiwiri.',
        );
      }

      if (nearestDealer != null || nearestOfficer != null) {
        parts.add(
          _buildAutomationReply(
            isChichewa: true,
            locationName: locationName,
            nearestOfficer: nearestOfficer,
            nearestDealer: nearestDealer,
          ),
        );
      }

      parts.add('Funso lanu: "$prompt".');
      if (reason != null && reason.trim().isNotEmpty) {
        parts.add('Chifukwa: $reason.');
      }
      return parts.join(' ');
    }

    final parts = <String>[offlineMessage];

    if (hasDiagnosis) {
      final d = diagnosis;
      parts.add(
        'Latest diagnosis: ${d.diagnosisName} (${(d.confidence * 100).toStringAsFixed(0)}% confidence).',
      );
      if ((d.treatment ?? '').trim().isNotEmpty) {
        parts.add('Treatment: ${d.treatment}.');
      }
      if ((d.prevention ?? '').trim().isNotEmpty) {
        parts.add('Prevention: ${d.prevention}.');
      }
    } else {
      parts.add(
        'I cannot find a diagnosis context yet, so please run a crop scan first and ask again.',
      );
    }

    if (nearestDealer != null || nearestOfficer != null) {
      parts.add(
        _buildAutomationReply(
          isChichewa: false,
          locationName: locationName,
          nearestOfficer: nearestOfficer,
          nearestDealer: nearestDealer,
        ),
      );
    }

    parts.add('Your question was: "$prompt".');
    if (reason != null && reason.trim().isNotEmpty) {
      parts.add('Reason: $reason.');
    }
    return parts.join(' ');
  }

  Future<String> askQuestion({
    required String prompt,
    required bool isChichewa,
    required List<AiChatMessage> history,
    DiagnosisResult? diagnosis,
    String? userId,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
    String? locationName,
    String? pageContext,
  }) async {
    if (locationName != null ||
        nearestOfficer != null ||
        nearestDealer != null) {
      await saveSupportContext(
        userId: userId,
        locationName: locationName,
        nearestOfficer: nearestOfficer,
        nearestDealer: nearestDealer,
      );
    }

    final cachedSupport = _loadSupportContext(userId: userId);
    final effectiveLocationName =
        (locationName != null && locationName.trim().isNotEmpty)
        ? locationName
        : cachedSupport?['locationName'] as String?;
    final effectiveNearestOfficer =
        nearestOfficer ?? _restoreOfficer(cachedSupport?['nearestOfficer']);
    final effectiveNearestDealer =
        nearestDealer ?? _restoreDealer(cachedSupport?['nearestDealer']);

    if (_geminiApiKey.isEmpty) {
      return _buildLocalAssistantFallback(
        isChichewa: isChichewa,
        prompt: prompt,
        diagnosis: diagnosis,
        locationName: effectiveLocationName,
        nearestOfficer: effectiveNearestOfficer,
        nearestDealer: effectiveNearestDealer,
        reason: 'GEMINI_API_KEY is missing or unreadable',
      );
    }

    final historyText = history
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

    final supportContext = _buildSupportContextForPrompt(
      isChichewa: isChichewa,
      locationName: effectiveLocationName,
      nearestOfficer: effectiveNearestOfficer,
      nearestDealer: effectiveNearestDealer,
    );

    final uiContext = pageContext ?? _currentUiContext;

    const systemPrompt =
        'You are CropDoc, a friendly agricultural AI assistant for farmers in Malawi. You help farmers understand crop diseases and farming advice. If a diagnosis is provided below, focus your answers on that diagnosis. If no diagnosis is provided, answer general farming questions. Keep ALL answers to maximum 3 short sentences. Always respond in the same language as the farmer\'s question. Never say unclear photo - that makes no sense in a chat context. When the NEARBY SUPPORT section lists real names, phone numbers, or districts for agro-dealers or extension officers, you MUST quote those exact details in your reply if the farmer asks about nearby help, dealers, officers, or where to buy inputs—never replace them with generic placeholders or say you cannot find local contacts.';

    final userPrompt =
        '''
    $systemPrompt

    Diagnosis context:
    $diagnosisContext

    $supportContext

    Current app screen: $uiContext

    Conversation history:
    $historyText

    Farmer's question:
    $prompt
    ''';

    http.Response? response;
    for (final model in _geminiModelCandidates) {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:generateContent',
      );

      try {
        final attempt = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': _geminiApiKey,
              },
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': userPrompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.1,
                  'maxOutputTokens': 800,
                },
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (attempt.statusCode == 404) {
          continue;
        }

        response = attempt;
        break;
      } on TimeoutException {
        return _buildLocalAssistantFallback(
          isChichewa: isChichewa,
          prompt: prompt,
          diagnosis: diagnosis,
          locationName: effectiveLocationName,
          nearestOfficer: effectiveNearestOfficer,
          nearestDealer: effectiveNearestDealer,
          reason: 'Gemini request timed out',
        );
      } on SocketException {
        return _buildLocalAssistantFallback(
          isChichewa: isChichewa,
          prompt: prompt,
          diagnosis: diagnosis,
          locationName: effectiveLocationName,
          nearestOfficer: effectiveNearestOfficer,
          nearestDealer: effectiveNearestDealer,
          reason: 'No internet or DNS/network failure',
        );
      } catch (e) {
        return _buildLocalAssistantFallback(
          isChichewa: isChichewa,
          prompt: prompt,
          diagnosis: diagnosis,
          locationName: effectiveLocationName,
          nearestOfficer: effectiveNearestOfficer,
          nearestDealer: effectiveNearestDealer,
          reason: 'Unexpected client error: ${e.runtimeType}',
        );
      }
    }

    if (response == null) {
      return _buildLocalAssistantFallback(
        isChichewa: isChichewa,
        prompt: prompt,
        diagnosis: diagnosis,
        locationName: effectiveLocationName,
        nearestOfficer: effectiveNearestOfficer,
        nearestDealer: effectiveNearestDealer,
        reason: 'No supported Gemini model responded successfully',
      );
    }

    if (response.statusCode >= 400) {
      final status = response.statusCode;
      if (status == 401 || status == 403) {
        return isChichewa
            ? 'Gemini API key yanu ikuwoneka ngati yosavomerezeka kapena yatsekedwa. Onani GEMINI_API_KEY mu .env.'
            : 'Your Gemini API key appears invalid or blocked. Check GEMINI_API_KEY in .env.';
      }
      if (status == 429) {
        return isChichewa
            ? 'Mafunso achuluka kwambiri pakadali pano (rate limit). Dikirani pangono kenako yesaninso.'
            : 'Too many AI requests right now (rate limited). Wait a moment and try again.';
      }
      return _buildLocalAssistantFallback(
        isChichewa: isChichewa,
        prompt: prompt,
        diagnosis: diagnosis,
        locationName: effectiveLocationName,
        nearestOfficer: effectiveNearestOfficer,
        nearestDealer: effectiveNearestDealer,
        reason: 'Gemini API returned HTTP ${response.statusCode}',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      return isChichewa
          ? 'AI yabweretsa yankho losamveka. Yesaninso.'
          : 'AI returned an unreadable response. Please try again.';
    }

    final candidates = (json['candidates'] as List<dynamic>? ?? const []);
    if (candidates.isEmpty) {
      return _buildLocalAssistantFallback(
        isChichewa: isChichewa,
        prompt: prompt,
        diagnosis: diagnosis,
        locationName: effectiveLocationName,
        nearestOfficer: effectiveNearestOfficer,
        nearestDealer: effectiveNearestDealer,
        reason: 'Gemini returned empty candidates',
      );
    }

    final content = candidates.first['content'] as Map<String, dynamic>?;
    final parts = (content?['parts'] as List<dynamic>? ?? const []);
    final text = parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join('\n')
        .trim();

    if (text.isEmpty) {
      return _buildLocalAssistantFallback(
        isChichewa: isChichewa,
        prompt: prompt,
        diagnosis: diagnosis,
        locationName: effectiveLocationName,
        nearestOfficer: effectiveNearestOfficer,
        nearestDealer: effectiveNearestDealer,
        reason: 'Gemini returned empty text',
      );
    }

    return text;
  }
}
