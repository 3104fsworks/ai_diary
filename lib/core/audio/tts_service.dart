import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../data/models/radio_voice_personality.dart';

/// Calls OpenAI TTS (`tts-1`) and saves the resulting MP3 to a given path.
///
/// Voice mapping (RadioVoiceType × RadioVoiceGender):
///   standard  female → nova     male → onyx
///   healing   female → shimmer  male → echo
///   energetic female → nova     male → fable  (speed 1.05)
///   dj        female → alloy    male → onyx
///
/// TODO(backend): replace inline key with a Cloudflare Workers proxy.
class TtsService {
  TtsService({String? apiKey, http.Client? client})
      : _apiKey = (apiKey?.isNotEmpty == true) ? apiKey! : _inlineKey,
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  // ignore: unused_field
  static const _inlineKey =
      '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';

  static const _endpoint = 'https://api.openai.com/v1/audio/speech';

  /// Synthesises [text] with the voice matching [voiceType] + [gender].
  /// Saves the MP3 to [destPath] (permanent location).
  ///
  /// Returns [destPath] on success.
  Future<String> synthesizeTo({
    required String text,
    required String destPath,
    RadioVoiceType voiceType = RadioVoiceType.standard,
    RadioVoiceGender gender = RadioVoiceGender.female,
  }) async {
    if (_apiKey.isEmpty) throw Exception('TTS: no API key configured.');
    if (text.isEmpty) throw Exception('TTS: text is empty.');

    final voice = _voiceName(voiceType, gender);
    final speed = _speed(voiceType);

    final res = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode({
            'model': 'tts-1',
            'input': text,
            'voice': voice,
            'response_format': 'mp3',
            'speed': speed,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String detail = '';
      try {
        final j = jsonDecode(res.body) as Map<String, dynamic>;
        detail =
            (j['error'] as Map?)?['message']?.toString() ?? res.body;
      } catch (_) {
        detail = res.body;
      }
      throw Exception('TTS error ${res.statusCode}: $detail');
    }

    final file = File(destPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(res.bodyBytes);
    return destPath;
  }

  /// Convenience: synthesise to a temp file (for one-off / test usage).
  Future<String> synthesizeTemp(
    String text, {
    RadioVoiceType voiceType = RadioVoiceType.standard,
    RadioVoiceGender gender = RadioVoiceGender.female,
  }) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final dest = '${dir.path}/tts_$ts.mp3';
    return synthesizeTo(
      text: text,
      destPath: dest,
      voiceType: voiceType,
      gender: gender,
    );
  }

  // ── Voice / speed mappings ────────────────────────────────────────────

  static String _voiceName(RadioVoiceType type, RadioVoiceGender gender) {
    final f = gender == RadioVoiceGender.female;
    return switch (type) {
      RadioVoiceType.standard => f ? 'nova' : 'onyx',
      RadioVoiceType.healing => f ? 'shimmer' : 'echo',
      RadioVoiceType.energetic => f ? 'nova' : 'fable',
      RadioVoiceType.dj => f ? 'alloy' : 'onyx',
    };
  }

  static double _speed(RadioVoiceType type) => switch (type) {
        RadioVoiceType.energetic => 1.05, // slightly peppier
        _ => 1.0,
      };

  void dispose() => _client.close();
}
