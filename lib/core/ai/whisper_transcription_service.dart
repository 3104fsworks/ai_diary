// ignore_for_file: prefer_initializing_formals
// The constructor maps a public named parameter (apiKey) to a private field
// (_apiKey). Initializing formals require matching names, which would expose
// an underscore-prefixed named parameter — invalid outside this library.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Sends a local audio file to OpenAI Whisper (`whisper-1`) and returns the
/// plain-text transcript.
///
/// Cost reference: $0.006 / minute (as of 2025).
/// With the 2-minute recording cap, worst case is $0.012 per diary entry.
///
/// Setup — choose ONE of the following:
///   A) Proxy mode (production): set [proxyUrl] to your Firebase Functions URL.
///      The function holds the real API key; the app never sees it.
///   B) BYOK mode: leave [proxyUrl] empty and supply [apiKey].
///      The key is stored in SharedPreferences on-device.
class WhisperTranscriptionService {
  final String _apiKey;

  /// Cloudflare Workers proxy base URL (e.g. https://ai-diary-proxy.you.workers.dev).
  /// When non-empty, transcription requests are routed through the proxy and
  /// [_apiKey] / [_inlineKey] are ignored.
  final String proxyUrl;

  /// Shared secret sent as `X-App-Token` header when using the proxy.
  /// Must match the `APP_TOKEN` secret configured on the Worker.
  /// Leave empty when the Worker does not validate tokens.
  final String appToken;

  WhisperTranscriptionService({
    required String apiKey,
    this.proxyUrl = '',
    this.appToken = '',
  }) : _apiKey = apiKey;

  static const _directEndpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  /// Transcribes [audioPath] (a local .m4a file) and returns the plain text.
  ///
  /// Returns null on network error or when no API key is available.
  /// [languageCode] is the BCP-47 language code ('ja', 'en', etc.) — passing
  /// the correct code improves accuracy and eliminates language-detection
  /// latency.
  Future<String?> transcribe({
    required String audioPath,
    required String languageCode,
  }) async {
    final file = File(audioPath);
    if (!await file.exists()) return null;

    if (proxyUrl.isNotEmpty) {
      return _transcribeViaProxy(audioPath: audioPath, languageCode: languageCode);
    }
    return _transcribeDirect(audioPath: audioPath, languageCode: languageCode);
  }

  // ── Direct path (BYOK / inline key) ────────────────────────────────────────

  Future<String?> _transcribeDirect({
    required String audioPath,
    required String languageCode,
  }) async {
    if (_apiKey.isEmpty) return null;
    final key = _apiKey;

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_directEndpoint))
        ..headers['Authorization'] = 'Bearer $key'
        ..fields['model'] = 'whisper-1'
        ..fields['language'] = _toIso639(languageCode)
        ..fields['response_format'] = 'text'
        ..files.add(await http.MultipartFile.fromPath('file', audioPath));

      return await _sendAndParse(request);
    } catch (e) {
      rethrow;
    }
  }

  // ── Proxy path (Cloudflare Workers) ────────────────────────────────────────

  Future<String?> _transcribeViaProxy({
    required String audioPath,
    required String languageCode,
  }) async {
    final endpoint = Uri.parse('$proxyUrl/whisper');

    try {
      final request = http.MultipartRequest('POST', endpoint)
        ..fields['model'] = 'whisper-1'
        ..fields['language'] = _toIso639(languageCode)
        ..fields['response_format'] = 'text'
        ..files.add(await http.MultipartFile.fromPath('file', audioPath));

      // Inject app token instead of Bearer auth — the Worker holds the real key.
      if (appToken.isNotEmpty) {
        request.headers['X-App-Token'] = appToken;
      }

      return await _sendAndParse(request);
    } catch (e) {
      rethrow;
    }
  }

  // ── Shared response parsing ─────────────────────────────────────────────────

  Future<String?> _sendAndParse(http.MultipartRequest request) async {
    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) {
      // response_format=text → body IS the transcript (no JSON wrapper).
      return body.trim();
    }

    // On error the API / proxy returns JSON — try to surface the message.
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final msg = (json['error'] as Map?)?['message'] as String?;
      throw Exception('Whisper error ${streamed.statusCode}: $msg');
    } catch (_) {
      throw Exception('Whisper error ${streamed.statusCode}: $body');
    }
  }

  /// Converts a BCP-47 languageCode ('ja', 'ja_JP', 'en', 'en-US') to
  /// the two-letter ISO-639-1 code that Whisper expects.
  static String _toIso639(String code) {
    final base = code.split(RegExp(r'[-_]')).first.toLowerCase();
    return base;
  }
}
