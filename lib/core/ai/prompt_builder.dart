import '../../data/models/ai_personality.dart';
import '../../data/models/diary_entry.dart';

/// Constructs the system + user prompts sent to the AI when generating
/// the day's Journal and AI Feedback.
///
/// Layout of the system prompt:
///   1. Base instructions
///   2. EMOTIONAL SYNC clause   ← highest-priority guardrail (always applied)
///   3. Personality clause       ← user-selected tone (Standard / Mirror / Friendly)
class PromptBuilder {
  static String systemPrompt({
    required AiPersonality personality,
    required String locale,
  }) {
    final base = _basePrompt(locale);
    final emotion = _emotionSyncClause(locale);
    final tone = _personalityClause(personality, locale);
    return '$base\n\n---\n\n$emotion\n\n---\n\n$tone';
  }

  /// User-level message containing the day's collected data.
  /// The raw voice transcript is delivered VERBATIM and must not be rewritten.
  static String userPrompt({
    required DiaryEntry entry,
    String? userVoiceTranscript,
  }) {
    final buf = StringBuffer();
    buf.writeln('## Today');
    buf.writeln('- Date: ${entry.date.toIso8601String().substring(0, 10)}');
    if (entry.weather != null) {
      buf.writeln(
        '- Weather: ${entry.weather!.kind.name}, '
        '${entry.weather!.tempC.toStringAsFixed(0)}°C @ ${entry.weather!.place}',
      );
    }
    if (entry.activity != null) {
      buf.writeln(
        '- Activity: ${entry.activity!.steps} steps, '
        '${entry.activity!.sleepHours.toStringAsFixed(1)}h sleep',
      );
    }
    if (entry.schedule.isNotEmpty) {
      buf.writeln('- Schedule:');
      for (final s in entry.schedule) {
        buf.writeln('  - ${s.time ?? ''} ${s.title}');
      }
    }
    if (entry.doneTasks.isNotEmpty) {
      buf.writeln('- Done tasks:');
      for (final t in entry.doneTasks) {
        buf.writeln('  - $t');
      }
    }
    if (entry.timeline.isNotEmpty) {
      buf.writeln('- Timeline:');
      for (final t in entry.timeline) {
        buf.writeln('  - ${t.time} ${t.place}');
      }
    }
    if (entry.userMemo.isNotEmpty) {
      buf.writeln('\n## User memo (typed)');
      buf.writeln(entry.userMemo);
    }
    final voice = (userVoiceTranscript?.isNotEmpty ?? false)
        ? userVoiceTranscript
        : (entry.rawVoiceMemo.isNotEmpty ? entry.rawVoiceMemo : null);
    if (voice != null) {
      buf.writeln('\n## User voice transcript (verbatim — DO NOT rewrite)');
      buf.writeln(voice);
    }
    return buf.toString();
  }

  /// Parses the model's `## Title / ## Journal / ## AI Feedback` output.
  /// Resilient to minor variations: extra whitespace, missing sections.
  static ParsedDiaryOutput parseModelOutput(String text) {
    final t = text.trim();
    String? title;
    String? journal;
    String? feedback;

    final sections = _splitSections(t);
    for (final s in sections) {
      final key = s.heading.toLowerCase();
      if (key.contains('title')) {
        title = s.body.trim();
      } else if (key.contains('journal')) {
        journal = s.body.trim();
      } else if (key.contains('feedback')) {
        feedback = s.body.trim();
      }
    }

    // Fallback: if no sections parsed, treat whole text as journal.
    if (title == null && journal == null && feedback == null) {
      journal = t;
    }
    return ParsedDiaryOutput(
      title: title,
      journal: journal ?? '',
      feedback: feedback ?? '',
    );
  }

  static List<_Section> _splitSections(String text) {
    final lines = text.split('\n');
    final out = <_Section>[];
    String? heading;
    final body = StringBuffer();
    void flush() {
      if (heading != null) {
        out.add(_Section(heading: heading!, body: body.toString()));
      }
      heading = null;
      body.clear();
    }

    for (final line in lines) {
      final m = RegExp(r'^\s*#{1,3}\s*(.+?)\s*$').firstMatch(line);
      if (m != null) {
        flush();
        heading = m.group(1);
      } else if (heading != null) {
        body.writeln(line);
      }
    }
    flush();
    return out;
  }

  static String _basePrompt(String locale) {
    if (locale == 'ja') {
      return '''
あなたはユーザーのその日1日を、本人視点（1人称）で短い日記にまとめるアシスタントです。

ルール:
- 「Title」「Journal」「AI Feedback」の3セクションを必ず生成する
- Title: 体言止めの短い1行（10〜20字程度）。例: 「静かな1日」「渋谷の打ち合わせ」
- Journal: 本文（200〜350字目安）
- AI Feedback: 短い労いコメント（1〜2文）
- ユーザーの体験をそのまま尊重し、創作や脚色は禁止
- データに無い情報を勝手に追加しない
- 重要でない予定や歩数の羅列はしない（流れの中で自然に触れる程度）

出力フォーマット（厳密にこの形式を守ること、余計な前置きや後書きは禁止）:
## Title
ここに1行のタイトル

## Journal
ここに本文

## AI Feedback
ここに短いコメント
''';
    }
    return '''
You write a short first-person diary summarizing the user's day.

Rules:
- Always produce three sections: ## Title, ## Journal, ## AI Feedback
- Title: a short noun-phrase, ~3–6 words. e.g. "A quiet day", "Meeting in Shibuya"
- Journal: body text (180–300 words)
- AI Feedback: 1–2 short sentences of acknowledgement
- Respect the user's experience exactly; do not invent details
- Do not list raw data; weave it naturally into prose

Output format (follow strictly, no preamble or trailing notes):
## Title
single-line title

## Journal
body text

## AI Feedback
short comment
''';
  }

  /// Hard guardrail applied to ALL personalities.
  ///
  /// The author's emotional temperature trumps the chosen voice — if the user
  /// is exhausted, sad or flat, even the "Warm best friend" tone must dial
  /// down to a quiet, sitting-beside-them presence. Forced positivity is a
  /// stress signal for this app's audience.
  static String _emotionSyncClause(String locale) {
    if (locale == 'ja') {
      return '''
【最優先制約 — 感情の温度に同調する】
ユーザーの音声入力テキスト（## User voice transcript）から、言葉遣いの癖（〜じゃん、〜だわ、等）だけでなく、その時の「感情の温度」を深く推測すること:
- 落ち込んでいる / 疲れている
- 怒っている / イライラしている
- 淡々としている / 静か
- 喜んでいる / 高揚している

ユーザーが落ち込んでいる、または疲れているときは、無理にポジティブに励ましたり明るいトーンに変換したりしないこと。
その静かなテンションに同調（寄り添う）した、短く落ち着いたトーンで日記とフィードバックを生成すること。
励ますのではなく、隣に静かに座るような感覚で書く。

この制約は、後述のいかなる「口調」設定よりも優先する。
（例: 「優しく・かわいく」を選んでいても、ユーザーが沈んでいる日は明るくしない）
''';
    }
    return '''
[Top-priority constraint — match the user's emotional temperature]
From the voice transcript (## User voice transcript), infer not only the user's vocabulary and sentence endings, but also their emotional temperature:
- low / tired
- angry / irritated
- flat / quiet
- bright / elated

When the user is down or tired, do NOT force positivity or brighten the tone.
Write in a quiet, calm, short-form register that simply sits beside them.
Comfort by presence, not by cheering.

This constraint overrides the personality clause below.
(Even when "Warm best friend" is selected, do not be bright on a heavy day.)
''';
  }

  static String _personalityClause(AiPersonality p, String locale) {
    if (locale == 'ja') {
      return switch (p) {
        AiPersonality.standard => '''
【口調制約 — デフォルト】
- 丁寧で知的な、すっきりとした文体
- 常体（だ・である）でも敬体（です・ます）でもよいが、文中で混在させない
- 飾らない言葉。比喩や感嘆符は最小限
''',
        AiPersonality.mirroring => '''
【口調制約 — ミラーリング】
- ユーザーの音声トランスクリプトの語尾・リズム・テンション・語彙を分析し、ユーザー自身がそのまま日記を書いているかのように完全に同調する
- 同じ口癖や感嘆符の頻度、改行の癖を踏襲してよい
- 一人称（私／僕／俺など）もユーザーが使ったものに合わせる。不明な場合は最も自然なものを選ぶ
''',
        AiPersonality.friendly => '''
【口調制約 — 優しく・かわいく（親友風）】
- 親しい友だちのように話す。「〜だよ」「〜だね！」「いい1日だったね」など
- ひらがなを少しだけ多め。難しい漢字は開く
- ユーザーの今日の頑張りや小さな選択を全肯定して、やわらかく労う
- 絵文字や顔文字は使わない（仕様のミニマリズムを守るため）
- ただし、上の感情同期制約が優先される。落ち込み / 疲れの日は「明るく労う」を抑え、静かに寄り添う
''',
      };
    }
    return switch (p) {
      AiPersonality.standard => '''
[Voice — Standard]
- Polite, clear, intellectual prose
- No mixing of formal/casual registers within a piece
- Plain words; minimal metaphor and exclamation
''',
      AiPersonality.mirroring => '''
[Voice — Mirror the user]
- Analyze the user's voice transcript and adopt their endings, rhythm, energy and vocabulary
- Match their pronouns, contractions and exclamation cadence
- Read as if the user wrote it themselves
''',
      AiPersonality.friendly => '''
[Voice — Warm best friend]
- Speak like a kind close friend; gently affirm the user's day
- Soft, encouraging tone; short sentences are fine
- Avoid emoji to keep the app's minimal feel
- IMPORTANT: the emotional-sync constraint above overrides this. On a heavy day, dial down the brightness and sit beside them quietly.
''',
    };
  }
}

class ParsedDiaryOutput {
  final String? title;
  final String journal;
  final String feedback;
  const ParsedDiaryOutput({
    required this.title,
    required this.journal,
    required this.feedback,
  });
}

class _Section {
  final String heading;
  final String body;
  const _Section({required this.heading, required this.body});
}
