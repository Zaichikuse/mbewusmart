import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../../core/error/failures.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/crop_type.dart';

class AnalyzeImageUseCase {
  String get _geminiApiKey {
    final keyCandidates = [
      dotenv.env['GEMINI_API_KEY'],
      dotenv.env['GOOGLE_API_KEY'],
      const String.fromEnvironment('GEMINI_API_KEY'),
    ];
    for (final candidate in keyCandidates) {
      var v = (candidate ?? '').trim();
      if ((v.startsWith('"') && v.endsWith('"')) ||
          (v.startsWith("'") && v.endsWith("'"))) {
        v = v.substring(1, v.length - 1).trim();
      }
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  List<String> get _modelCandidates => [
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-2.5-flash',
  ];

  Future<Either<Failure, DiagnosisResult>> call(
    String imagePath,
    CropType cropType, {
    Uint8List? imageBytes, // ← Accept bytes directly from image picker
  }) async {
    try {
      // ── 1. Validate API key ────────────────────────────────────────
      final apiKey = _geminiApiKey;
      print('[Gemini] API key present: ${apiKey.isNotEmpty}');
      if (apiKey.isEmpty) {
        return Left(ServerFailure('API key missing. Check your .env file.'));
      }

      // ── 2. Get image bytes ─────────────────────────────────────────
      // Use passed bytes first (most reliable on Android)
      // Fall back to reading from file path
      Uint8List finalBytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        print('[Gemini] Using provided image bytes: ${imageBytes.length}');
        finalBytes = imageBytes;
      } else {
        final imageFile = File(imagePath);
        print('[Gemini] Reading image bytes from path: $imagePath');
        if (!await imageFile.exists()) {
          return Left(ServerFailure('Image file not found. Please try again.'));
        }
        finalBytes = await imageFile.readAsBytes();
        print('[Gemini] Read image bytes from file: ${finalBytes.length}');
      }

      if (finalBytes.isEmpty) {
        return Left(ServerFailure('Image is empty. Please try again.'));
      }

      final base64Image = base64Encode(finalBytes);

      // Always use jpeg for Gemini — most reliable format
      const mimeType = 'image/jpeg';
      final cropName = cropType.displayName;
      print('[Gemini] Crop type: $cropName');

      // ── 3. Build prompt ────────────────────────────────────────────
      final prompt =
          '''
You are CropDoc, an expert agricultural diagnostic AI for smallholder farmers in Malawi, Africa.

Your task: Carefully analyze this $cropName crop image and provide an accurate diagnosis.

IMPORTANT RULES:
- Look very carefully at the leaves, stems, color, spots, patterns in the image
- Give a REAL diagnosis based on what you actually see
- If the plant looks healthy with no visible problems, say "healthy"
- Only say "unclear" if the image is completely black, completely blurred, or has no visible plant
- Be confident — farmers need real answers, not vague responses
- confidence must be an honest integer 60-99 for clear images
- Return ONLY the JSON below with no other text, no markdown, no backticks

{
  "diagnosis_type": "healthy",
  "name": "Healthy Maize Crop",
  "name_chichewa": "Chimanga Cha Bwino",
  "scientific_name": null,
  "confidence": 85,
  "severity": "low",
  "symptoms_observed": ["describe what you actually see in the image"],
  "causing_factors": "explain the cause or null if healthy",
  "recommendation": "what the farmer should do right now",
  "treatment": "specific treatment steps or null if healthy",
  "prevention": "how to prevent this in future",
  "pesticide_remedy": "specific pesticide name and dosage or null",
  "consult_expert": false
}

Replace ALL values above with your REAL diagnosis of this $cropName image.
diagnosis_type must be one of: disease, pest, nutritional_deficiency, healthy, unclear
severity must be one of: low, medium, high
''';

      // ── 4. Call Gemini ─────────────────────────────────────────────
      for (final model in _modelCandidates) {
        print('[Gemini] Using model: $model');
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/$model:generateContent',
        );
        print('[Gemini] Request URL: $uri');

        http.Response response;
        try {
          response = await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'x-goog-api-key': apiKey,
                },
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {
                          'inline_data': {
                            'mime_type': mimeType,
                            'data': base64Image,
                          },
                        },
                        {'text': prompt},
                      ],
                    },
                  ],
                  'generationConfig': {
                    'temperature': 0.1,
                    'topP': 0.8,
                    'maxOutputTokens': 1000,
                  },
                }),
              )
              .timeout(const Duration(seconds: 40));
        } on TimeoutException {
          print('[Gemini] Timeout after 40s');
          return Left(
            ServerFailure(
              'Request timed out. Check your internet and try again.',
            ),
          );
        } on SocketException {
          print('[Gemini] No internet connection');
          return Left(
            ServerFailure(
              'No internet connection. Please connect and try again.',
            ),
          );
        }

        print('[Gemini] Status code: ${response.statusCode}');
        print('[Gemini] Raw response (before parsing): ${response.body}');

        if (response.statusCode == 404) continue;

        if (response.statusCode == 401 || response.statusCode == 403) {
          return Left(
            ServerFailure(
              'API key invalid. Please regenerate your Gemini API key.',
            ),
          );
        }

        if (response.statusCode == 429) {
          return Left(
            ServerFailure('Too many requests. Wait a moment and try again.'),
          );
        }

        if (response.statusCode >= 400) {
          return Left(
            ServerFailure(
              'AI error (${response.statusCode}). Please try again.',
            ),
          );
        }

        // ── 5. Parse response ──────────────────────────────────────
        Map<String, dynamic> responseJson;
        try {
          responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          print('[Gemini] JSON parse error (top-level): $e');
          final preview = _truncateForUi(response.body);
          return Left(
            ServerFailure('AI response parse error. Raw response: $preview'),
          );
        }

        final geminiCandidates = responseJson['candidates'] as List<dynamic>?;

        if (geminiCandidates == null || geminiCandidates.isEmpty) {
          final body = response.body;
          final preview = body.length > 300 ? body.substring(0, 300) : body;
          return Left(ServerFailure('AI returned no result: $preview'));
        }

        final content =
            geminiCandidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;

        if (parts == null || parts.isEmpty) {
          return Left(
            ServerFailure('AI returned empty result. Please try again.'),
          );
        }

        final rawText = (parts.first['text'] as String? ?? '').trim();

        if (rawText.isEmpty) {
          return Left(
            ServerFailure('AI returned empty text. Please try again.'),
          );
        }

        // ── 6. Extract JSON ────────────────────────────────────────
        var cleaned = rawText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .replaceAll('`', '')
            .trim();

        final jsonStart = cleaned.indexOf('{');
        final jsonEnd = cleaned.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          cleaned = cleaned.substring(jsonStart, jsonEnd + 1);
        }

        Map<String, dynamic> diagnosisJson;
        try {
          diagnosisJson = jsonDecode(cleaned) as Map<String, dynamic>;
        } catch (e) {
          print('[Gemini] JSON parse error (diagnosis body): $e');
          print('[Gemini] Cleaned response text: $cleaned');
          final preview = _truncateForUi(rawText);
          return Left(
            ServerFailure('AI response parse error. Raw response: $preview'),
          );
        }

        return Right(_buildResultFromJson(diagnosisJson, imagePath, cropType));
      }

      return Left(
        ServerFailure(
          'Could not connect to AI. Check your internet and try again.',
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  String _truncateForUi(String text, {int maxChars = 1000}) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}...';
  }

  DiagnosisResult _buildResultFromJson(
    Map<String, dynamic> json,
    String imagePath,
    CropType cropType,
  ) {
    // Parse confidence
    final confidenceRaw = json['confidence'];
    double confidence = 0.70;
    if (confidenceRaw is int) {
      confidence = confidenceRaw / 100.0;
    } else if (confidenceRaw is double) {
      confidence = confidenceRaw > 1.0 ? confidenceRaw / 100.0 : confidenceRaw;
    } else if (confidenceRaw is String) {
      confidence = (double.tryParse(confidenceRaw) ?? 70.0) / 100.0;
    }
    confidence = confidence.clamp(0.0, 1.0);

    // Parse diagnosis type
    final typeStr = (json['diagnosis_type'] as String? ?? 'healthy')
        .toLowerCase()
        .trim();
    DiagnosisType type;
    switch (typeStr) {
      case 'disease':
        type = DiagnosisType.disease;
        break;
      case 'pest':
        type = DiagnosisType.pest;
        break;
      case 'nutritional_deficiency':
        type = DiagnosisType.deficiency;
        break;
      case 'healthy':
        type = DiagnosisType.healthy;
        break;
      default:
        type = DiagnosisType.healthy;
    }

    // Parse severity
    final severityStr = (json['severity'] as String? ?? 'low')
        .toLowerCase()
        .trim();
    Severity severity;
    switch (severityStr) {
      case 'high':
        severity = Severity.high;
        break;
      case 'medium':
        severity = Severity.medium;
        break;
      default:
        severity = Severity.low;
    }

    final bool consultExpert =
        confidence < 0.60 || (json['consult_expert'] as bool? ?? false);

    var recommendation =
        json['recommendation'] as String? ??
        'Please consult your extension officer.';

    if (consultExpert && confidence < 0.60) {
      recommendation = '$recommendation Please consult your extension officer.';
    }

    return DiagnosisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      type: type,
      diagnosisName: json['name'] as String? ?? 'Unknown Condition',
      diagnosisNameChichewa:
          json['name_chichewa'] as String? ??
          json['name'] as String? ??
          'Sidziwika',
      confidence: confidence,
      severity: severity,
      recommendation: recommendation,
      treatment: json['treatment'] as String?,
      prevention: json['prevention'] as String?,
      timestamp: DateTime.now(),
      cropType: cropType,
      scientificName: json['scientific_name'] as String?,
      causingFactors: json['causing_factors'] as String?,
      pesticideRemedy: json['pesticide_remedy'] as String?,
    );
  }
}
