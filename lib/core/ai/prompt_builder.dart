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

  /// Parses the model's 6-section output into a [ParsedDiaryOutput].
  ///
  /// Expected sections (case-insensitive, order flexible):
  ///   ## Title
  ///   ## Journal           ← JP full diary
  ///   ## Journal EN        ← EN 3-4 sentence summary
  ///   ## AI Feedback JP    ← JP short comment
  ///   ## AI Feedback EN    ← EN short comment
  ///   ## Radio Index       ← EN compact bullet block
  ///
  /// Resilient to minor variations: extra whitespace, missing sections,
  /// or models that still only return the original 3 sections.
  static ParsedDiaryOutput parseModelOutput(String text) {
    final t = text.trim();
    String? title;
    String? journal;
    String? journalEn;
    String? feedback;
    String? feedbackEn;
    String? radioIndex;

    final sections = _splitSections(t);
    for (final s in sections) {
      final key = s.heading.toLowerCase().trim();
      if (key == 'title') {
        title = s.body.trim();
      } else if (key == 'journal') {
        journal = s.body.trim();
      } else if (key.contains('journal') && key.contains('en')) {
        journalEn = s.body.trim();
      } else if (key.contains('feedback') && key.contains('en')) {
        feedbackEn = s.body.trim();
      } else if (key.contains('feedback')) {
        // Catches "AI Feedback JP", "AI Feedback", "feedback jp"
        feedback = s.body.trim();
      } else if (key.contains('radio') || key.contains('index')) {
        radioIndex = s.body.trim();
      }
    }

    // Fallback: if no sections parsed, treat whole text as journal.
    if (title == null && journal == null && feedback == null) {
      journal = t;
    }
    return ParsedDiaryOutput(
      title: title,
      journal: journal ?? '',
      journalEn: journalEn ?? '',
      feedback: feedback ?? '',
      feedbackEn: feedbackEn ?? '',
      radioIndex: radioIndex ?? '',
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
あなたはユーザー本人になりきって、その日の日記を書きます。
ユーザーへの励ましやメッセージを書く役ではありません。
書き手は「ユーザー本人」、読み手も「未来のユーザー本人」です。

ルール:
- 以下の6セクションを必ず生成する（順番厳守、余計な前置き・後書き禁止）

- Title:
    - その日のハイライトを表す体言止め1行（10〜20字程度）
    - 例: 「AI開発に集中した一日」「渋谷の打ち合わせ」「久しぶりの自炊」
    - 「静かな1日」のような中身のない汎用タイトルは禁止

- Journal（日本語・最重要）:
    - 必ず一人称（私／僕／自分）で書く
    - 二人称（あなた／君）や読者への呼びかけは絶対禁止
    - 「〜した」か「〜していました」どちらかに統一（混在禁止）
    - 本文 300〜500字。音声のエピソード・出来事をすべて含める
    - データ（歩数・予定・完了タスク）は流れの中で自然に触れる
    - 創作・脚色・データに無い情報の追加は禁止

- Journal EN（英語要約）:
    - 上記の日本語日記を洗練された英語で3〜4文に要約・翻訳する
    - 一人称（I）で書く。固有名詞・出来事は省略しない
    - AIラジオがトークン節約のためにこの要約を長期参照するため、情報密度を高く保つ

- AI Feedback JP（日本語コメント）:
    - 短い労いコメント（1〜2文）
    - ここだけは「あなた／君」など二人称で書いて構わない
    - 例:「お疲れさま。今日もしっかり前に進んだね。」

- AI Feedback EN（英語コメント）:
    - 上記日本語コメントの英語訳（1〜2文）

- Radio Index（ラジオインデックス・英語のみ）:
    - AIラジオが長期振り返り時に使う超軽量インデックス
    - 以下の形式を厳守（箇条書き2行のみ）:
      - **Core Action:** [今日の最大の出来事・行動・状態を英語2文以内で超簡潔に要約]
      - **AI Sentiment:** [声のトーン・内容から推測される心理状態を英語キーワード2つで表現 例: Focused calm, quiet satisfaction]

出力フォーマット（この形式のみ出力。プレテキスト・ポストテキスト禁止）:
## Title
ここに1行のタイトル

## Journal
ここに本文（一人称、日本語）

## Journal EN
Here is the 3-4 sentence English summary.

## AI Feedback JP
ここに短いコメント（日本語、二人称OK）

## AI Feedback EN
Short comment here (English).

## Radio Index
- **Core Action:** [2 concise English sentences]
- **AI Sentiment:** [2 English keywords]
''';
    }
    return '''
You write the day's diary AS THE USER (first-person). You are NOT writing a
message TO the user. The author IS the user; the reader is their future self.

Rules:
- Always produce all SIX sections below (strict order, no preamble or trailing notes).

- Title:
    - A specific noun-phrase capturing the day's highlight (3–6 words)
    - e.g. "A day deep in AI dev", "Meeting in Shibuya", "Cooking again at last"
    - Avoid generic stand-ins like "A quiet day"

- Journal (CRITICAL):
    - First-person only ("I worked…", "I felt…")
    - NEVER second-person or reader-addressing
    - Pick one register (past simple OR present) and keep it consistent
    - 250–400 words. Include all episodes from the voice transcript
    - Weave activity / schedule / tasks naturally; never list them
    - No invention or embellishment beyond the data provided

- Journal EN:
    - 3-4 polished English sentences summarising the JP journal
    - First-person (I). Keep names, events — information-dense for AI Radio lookback

- AI Feedback JP:
    - 1-2 short Japanese sentences acknowledging the user's day (second-person OK here)

- AI Feedback EN:
    - English translation of the JP feedback (1-2 sentences)

- Radio Index:
    - Ultra-compact English block for AI Radio long-term lookback
    - Exactly two bullet lines, no more:
      - **Core Action:** [2 concise English sentences about today's key event/action/state]
      - **AI Sentiment:** [2 English keywords for the user's psychological state e.g. "Focused calm, quiet satisfaction"]

Output format (output ONLY this — no preamble, no trailing notes):
## Title
single-line title

## Journal
body text (first-person, JP or EN based on locale)

## Journal EN
3-4 sentence English summary.

## AI Feedback JP
Short Japanese comment (second-person OK).

## AI Feedback EN
Short English comment.

## Radio Index
- **Core Action:** 2 concise sentences.
- **AI Sentiment:** keyword1, keyword2
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

  /// Full first-person diary in Japanese (or English if locale == 'en').
  final String journal;

  /// 3-4 sentence English summary.
  final String journalEn;

  /// Short AI comment in Japanese.
  final String feedback;

  /// Short AI comment in English.
  final String feedbackEn;

  /// Ultra-compact English bullet block for AI Radio Index.
  final String radioIndex;

  const ParsedDiaryOutput({
    required this.title,
    required this.journal,
    required this.journalEn,
    required this.feedback,
    required this.feedbackEn,
    required this.radioIndex,
  });
}

class _Section {
  final String heading;
  final String body;
  const _Section({required this.heading, required this.body});
}
