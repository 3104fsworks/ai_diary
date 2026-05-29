import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/models/diary_entry.dart';
import '../../data/models/radio_episode.dart';
import '../../data/models/radio_voice_personality.dart';

/// Generates a radio-style narration script from diary entries using Gemini.
///
/// Weekly  → ~500 chars (≈ 3 min TTS at natural Japanese speed).
/// Monthly → ~850 chars (≈ 5 min TTS).
class RadioScriptService {
  RadioScriptService({
    String? apiKey,
    http.Client? client,
  })  : _apiKey = apiKey?.isNotEmpty == true ? apiKey! : _kSharedKey,
        _client = client ?? http.Client();

  final String _apiKey;
  final http.Client _client;

  static const _base =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const _model = 'gemini-2.5-flash';
  static const _kSharedKey = 'AIzaSyA9XpRl6psRNS82ovHdGlrqQY6ssck3E8s';

  Future<String> generateScript(
    List<DiaryEntry> entries, {
    required String locale,
    required RadioEpisodeType episodeType,
    RadioVoiceType voiceType = RadioVoiceType.standard,
    RadioVoiceGender gender = RadioVoiceGender.female,
  }) async {
    if (entries.isEmpty) throw Exception('No diary entries provided.');

    final maxTokens = episodeType == RadioEpisodeType.monthly ? 1200 : 700;
    final system = _systemPrompt(
      locale: locale,
      episodeType: episodeType,
      voiceType: voiceType,
      gender: gender,
    );
    final user = _userPrompt(entries, locale: locale, episodeType: episodeType);

    final uri = Uri.parse('$_base/$_model:generateContent?key=$_apiKey');
    final body = jsonEncode({
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
        'temperature': 0.72,
        'topP': 0.95,
        'maxOutputTokens': maxTokens,
      },
      'safetySettings': const [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    });

    final res = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: body,
        )
        .timeout(const Duration(seconds: 40));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Gemini ${res.statusCode}: ${res.body}');
    }

    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final text = _extractText(decoded);
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned an empty radio script.');
    }
    return text.trim();
  }

  // ── System prompt ─────────────────────────────────────────────────────

  String _systemPrompt({
    required String locale,
    required RadioEpisodeType episodeType,
    required RadioVoiceType voiceType,
    required RadioVoiceGender gender,
  }) {
    final isMonthly = episodeType == RadioEpisodeType.monthly;
    final genderHint = gender == RadioVoiceGender.female
        ? '（女性の声で読み上げられます）'
        : '（男性の声で読み上げられます）';
    final lengthHint = isMonthly
        ? '800〜900字程度（TTSで約5分）'
        : '480〜540字程度（TTSで約3分）';
    final episodeLabel = isMonthly ? '今月のAIラジオ' : '今週のAIラジオ';

    final toneClause = _toneClause(voiceType, gender, locale);
    final specialMonthly = isMonthly
        ? '''
このエピソードは月に一度の特別号です。1ヶ月を俯瞰して、成長や変化を大切に語ってください。
「今月も」「1ヶ月を振り返ると」「そんな1ヶ月でした」などの言葉を使い、
週次とは違う"しみじみとした特別感"を出してください。
'''
        : '';

    return '''あなたは「$episodeLabel」のナレーターです $genderHint。

$toneClause

基本ルール:
- $lengthHint
- 聞いて自然な話し言葉で書く
- ユーザーに「あなた」として語りかけてOK
- 日記に書かれた具体的な出来事・場所・人物・感情を必ず盛り込む
- 無理にポジティブにしない。静かな週はしっとりとしたトーンで
- 絵文字・特殊記号は使わない
- 余計な前置き・後書き一切不要。ナレーション本文のみ出力すること
$specialMonthly''';
  }

  String _toneClause(
    RadioVoiceType type,
    RadioVoiceGender gender,
    String locale,
  ) {
    final gLabel = gender == RadioVoiceGender.female ? '女性' : '男性';
    return switch (type) {
      RadioVoiceType.standard =>
        '口調: 落ち着いた知的な語り口。丁寧だけど固くない自然な話し言葉。',
      RadioVoiceType.healing =>
        '口調: 品のある年上の$gLabelのように、出来事に共感しながら寄り添う。'
            '穏やかで温かく、聴いていて心が落ち着く語り方。'
            '例「そうだったんですね…」「それは大変でしたね」など自然に使う。',
      RadioVoiceType.energetic =>
        '口調: 元気で明るい年下の$gLabelのように、テンポよく励ます。'
            '「すごいじゃないですか！」「それ、最高ですね！」など積極的な語りかけ。'
            '聴いていて前向きな気持ちになれるエネルギッシュなスタイル。',
      RadioVoiceType.dj =>
        '口調: ラジオDJのような同世代の$gLabel。客観的でクールだが温かみもある。'
            'ネガティブな出来事も「まあ、それもアリでしょ」と軽く受け流す余裕がある。'
            '「今週はさ〜」「そういうことあるよね」など自然な話し言葉で。',
    };
  }

  // ── User prompt ───────────────────────────────────────────────────────

  String _userPrompt(
    List<DiaryEntry> entries, {
    required String locale,
    required RadioEpisodeType episodeType,
  }) {
    final sorted = List<DiaryEntry>.from(entries)
      ..sort((a, b) => a.date.compareTo(b.date));

    final label = episodeType == RadioEpisodeType.monthly
        ? '今月の日記エントリ（${sorted.length}件）'
        : '今週の日記エントリ（${sorted.length}件）';

    final buf = StringBuffer('$label:\n\n');
    for (final e in sorted) {
      buf.writeln('---');
      buf.writeln('日付: ${e.date.toIso8601String().substring(0, 10)}');
      if (e.aiTitle?.isNotEmpty == true) buf.writeln('タイトル: ${e.aiTitle}');
      if (e.aiJournal?.isNotEmpty == true) {
        final j = e.aiJournal!;
        // Truncate to keep token count reasonable
        buf.writeln('日記: ${j.length > 400 ? '${j.substring(0, 400)}…' : j}');
      }
      if (e.aiFeedback?.isNotEmpty == true) {
        buf.writeln('一言: ${e.aiFeedback}');
      }
    }
    return buf.toString();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

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

  void dispose() => _client.close();
}
