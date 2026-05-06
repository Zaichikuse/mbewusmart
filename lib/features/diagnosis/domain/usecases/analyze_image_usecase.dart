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

  // FIXED: Gemini 1.5 models are fully shut down (return 404).
  // Using current stable models. Loop tries each in order — if quota or
  // a transient 404 hits the first, the next is tried automatically.
  List<String> get _modelCandidates => const [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-flash-latest',
  ];

  Future<Either<Failure, DiagnosisResult>> call(
    String imagePath,
    CropType cropType, {
    Uint8List? imageBytes,
  }) async {
    try {
      final apiKey = _geminiApiKey;
      print('[Gemini] API key present: ${apiKey.isNotEmpty}');
      if (apiKey.isEmpty) {
        return Left(ServerFailure('API key missing. Check your .env file.'));
      }

      Uint8List finalBytes;
      if (imageBytes != null && imageBytes.isNotEmpty) {
        print('[Gemini] Using provided image bytes: ${imageBytes.length}');
        finalBytes = imageBytes;
      } else {
        final imageFile = File(imagePath);
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
      const mimeType = 'image/jpeg';
      final cropName = cropType.displayName;
      print('[Gemini] Crop type: $cropName');

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

      // Track the last error category so we can give a useful message
      // if every model fails.
      int lastTransientStatus = 0;
      int last404Status = 0;

      // Build the request body once — it's the same for every model.
      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topP': 0.8,
          // Raised from 400 — Gemini 2.5 uses "thinking tokens" before
          // emitting the answer, and 400 wasn't enough for thinking +
          // the full JSON, causing MAX_TOKENS truncation mid-output.
          'maxOutputTokens': 1500,
          // Disable thinking for this call — we want a structured JSON
          // answer, not chain-of-thought reasoning. This makes the call
          // faster, cheaper, and avoids the truncation problem entirely.
          'thinkingConfig': {'thinkingBudget': 0},
        },
      });

      modelLoop:
      for (final model in _modelCandidates) {
        // FIXED: /v1beta/ instead of /v1/ — current Gemini models are
        // exposed reliably on v1beta. The v1 endpoint was the cause of
        // the 404 "model not found" errors in the logs.
        final uri = Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/$model:generateContent',
        );

        // Retry the SAME model up to 3 times on transient 5xx errors
        // (503 "high demand" is the most common). Exponential backoff:
        // 1s, 2s, 4s. If it still fails, fall through to the next model.
        http.Response? response;
        const maxAttempts = 3;
        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
          print('[Gemini] Using model: $model (attempt $attempt/$maxAttempts)');
          print('[Gemini] Request URL: $uri');

          try {
            response = await http
                .post(
                  uri,
                  headers: {
                    'Content-Type': 'application/json',
                    'x-goog-api-key': apiKey,
                  },
                  body: requestBody,
                )
                .timeout(const Duration(seconds: 40));
          } on TimeoutException {
            return Left(
              ServerFailure(
                'Request timed out. Check your internet and try again.',
              ),
            );
          } on SocketException {
            return Left(
              ServerFailure(
                'No internet connection. Please connect and try again.',
              ),
            );
          }

          print('[Gemini] Status code: ${response.statusCode}');
          print('[Gemini] Raw response (before parsing): ${response.body}');

          final code = response.statusCode;

          // Transient server errors → wait and retry the same model.
          // 503 = overloaded ("high demand"), 500/502/504 = upstream blip.
          final isTransient =
              code == 500 || code == 502 || code == 503 || code == 504;
          if (isTransient && attempt < maxAttempts) {
            lastTransientStatus = code;
            final waitMs = 1000 * (1 << (attempt - 1)); // 1s, 2s, 4s
            print('[Gemini] Transient $code — retrying in ${waitMs}ms');
            await Future.delayed(Duration(milliseconds: waitMs));
            continue;
          }

          // Done retrying this model — break out to evaluate the result.
          break;
        }

        if (response == null) {
          // Should never happen, but be defensive.
          continue;
        }

        final code = response.statusCode;

        // Model not available for this key → try next model.
        if (code == 404) {
          last404Status = 404;
          continue modelLoop;
        }
        // Auth problems are fatal — no point trying other models.
        if (code == 401 || code == 403) {
          return Left(
            ServerFailure(
              'API key invalid. Please regenerate your Gemini API key.',
            ),
          );
        }
        // Quota or persistent overload on this model → try the next one.
        if (code == 429 ||
            code == 500 ||
            code == 502 ||
            code == 503 ||
            code == 504) {
          lastTransientStatus = code;
          continue modelLoop;
        }
        if (code >= 400) {
          return Left(ServerFailure('AI error ($code). Please try again.'));
        }

        Map<String, dynamic> responseJson;
        try {
          responseJson = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          return Left(ServerFailure('AI response parse error.'));
        }

        final geminiCandidates = responseJson['candidates'] as List<dynamic>?;
        if (geminiCandidates == null || geminiCandidates.isEmpty) {
          final preview = response.body.length > 300
              ? response.body.substring(0, 300)
              : response.body;
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
          return Left(
            ServerFailure(
              'AI response parse error. Raw: ${cleaned.substring(0, cleaned.length > 200 ? 200 : cleaned.length)}',
            ),
          );
        }

        return Right(_buildResultFromJson(diagnosisJson, imagePath, cropType));
      }

      // If we reach here, every model failed across retries.
      if (lastTransientStatus == 503) {
        return Left(
          ServerFailure(
            'Gemini servers are currently overloaded. '
            'Please wait a minute and try again.',
          ),
        );
      }
      if (last404Status == 404) {
        return Left(
          ServerFailure(
            'No supported Gemini model available for your API key. '
            'Make sure your key is from https://aistudio.google.com/apikey '
            'and that the Generative Language API is enabled.',
          ),
        );
      }
      return Left(
        ServerFailure(
          'AI quota exceeded across all models. Please wait a moment and try again.',
        ),
      );
    } catch (e) {
      return Left(ServerFailure('Unexpected error: ${e.toString()}'));
    }
  }

  DiagnosisResult _buildResultFromJson(
    Map<String, dynamic> json,
    String imagePath,
    CropType cropType,
  ) {
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
