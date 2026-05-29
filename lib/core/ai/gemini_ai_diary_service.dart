import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/ai_personality.dart';
import '../../data/models/diary_entry.dart';
import 'ai_diary_service.dart';
import 'prompt_builder.dart';

/// Google Gemini implementation of [AiDiaryService].
/// Uses the REST `generateContent` endpoint — no heavy SDK.
///
/// Supports two transport modes:
///   • **Proxy mode** (production): set [proxyUrl] to your Cloudflare Workers
///     URL. The worker holds the real API key; the app sends no key at all.
///   • **Direct mode** (beta/BYOK): leave [proxyUrl] empty and supply [apiKey].
class GeminiAiDiaryService implements AiDiaryService {
  GeminiAiDiaryService({
    required this.apiKey,
    // gemini-1.5-flash was retired for new API keys in Sept 2025 (404).
    // gemini-2.0-flash had a tight per-project free-tier (429 on 2nd call).
    // gemini-2.5-flash is the current default with the most generous free
    // tier — switch back if it gets deprecated.
    this.model = 'gemini-2.5-flash',
    this.timeout = const Duration(seconds: 30),
    this.proxyUrl = '',
    this.appToken = '',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final Duration timeout;

  /// Cloudflare Workers proxy base URL (e.g. https://ai-diary-proxy.you.workers.dev).
  /// When non-empty, requests are routed through the proxy and [apiKey] is ignored.
  final String proxyUrl;

  /// Shared secret sent as `X-App-Token` when using the proxy.
  final String appToken;

  final http.Client _client;

  static const _base = 'https://generativelanguage.googleapis.com/v1beta/models';

  @override
  Future<AiGenerationResult> generateDiary({
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  }) async {
    final system = PromptBuilder.systemPrompt(
      personality: personality,
      locale: localeCode,
    );
    final user = PromptBuilder.userPrompt(
      entry: entry,
      userVoiceTranscript: voiceTranscript,
    );

    // The Gemini request payload (same structure regardless of transport).
    final geminiBody = {
      'systemInstruction': {
        'parts': [
          {'text': system},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': user},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.6,
        'topP': 0.95,
        'maxOutputTokens': 2000,
      },
      'safetySettings': const [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'},
      ],
    };

    final http.Response res;
    if (proxyUrl.isNotEmpty) {
      // ── Proxy mode ─────────────────────────────────────────────────────────
      // POST {proxyUrl}/gemini with JSON wrapper: { model, body: <geminiBody> }
      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };
      if (appToken.isNotEmpty) headers['X-App-Token'] = appToken;

      res = await _client
          .post(
            Uri.parse('$proxyUrl/gemini'),
            headers: headers,
            body: jsonEncode({'model': model, 'body': geminiBody}),
          )
          .timeout(timeout);
    } else {
      // ── Direct mode (BYOK / inline key) ────────────────────────────────────
      final uri = Uri.parse('$_base/$model:generateContent?key=$apiKey');
      res = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(geminiBody),
          )
          .timeout(timeout);
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw GeminiException(
        statusCode: res.statusCode,
        message: _extractErrorMessage(res.body) ?? res.body,
      );
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final text = _extractText(decoded);
    if (text == null || text.isEmpty) {
      throw const GeminiException(
        statusCode: 200,
        message: 'Gemini returned an empty response.',
      );
    }

    final parsed = PromptBuilder.parseModelOutput(text);
    return AiGenerationResult(
      journal: parsed.journal,
      feedback: parsed.feedback,
      titleSuggestion: parsed.title,
      journalEn: parsed.journalEn.isNotEmpty ? parsed.journalEn : null,
      feedbackEn: parsed.feedbackEn.isNotEmpty ? parsed.feedbackEn : null,
      radioIndex: parsed.radioIndex.isNotEmpty ? parsed.radioIndex : null,
    );
  }

  String? _extractText(Map<String, dynamic> body) {
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final first = candidates.first;
    if (first is! Map<String, dynamic>) return null;
    final content = first['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final buf = StringBuffer();
    for (final p in parts) {
      if (p is Map<String, dynamic> && p['text'] is String) {
        buf.write(p['text'] as String);
      }
    }
    final s = buf.toString();
    return s.isEmpty ? null : s;
  }

  String? _extractErrorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['error'] is Map) {
        final err = j['error'] as Map;
        return err['message'] as String?;
      }
    } catch (_) {}
    return null;
  }

  void dispose() => _client.close();
}

class GeminiException implements Exception {
  final int statusCode;
  final String message;
  const GeminiException({required this.statusCode, required this.message});

  @override
  String toString() => 'GeminiException($statusCode): $message';
}
