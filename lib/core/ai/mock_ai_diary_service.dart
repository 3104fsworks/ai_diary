import '../../data/models/ai_personality.dart';
import '../../data/models/diary_entry.dart';
import 'ai_diary_service.dart';

/// Canned output that demonstrates the personality switch + emotion sync
/// before a real provider is wired up.
class MockAiDiaryService implements AiDiaryService {
  @override
  Future<AiGenerationResult> generateDiary({
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final ja = localeCode == 'ja';
    final voice = (voiceTranscript?.isNotEmpty ?? false)
        ? voiceTranscript!
        : entry.rawVoiceMemo;

    final mood = _inferMood(voice);

    // Heavy days override personality brightness (matches the system prompt rule).
    if (mood == _Mood.low) {
      return AiGenerationResult(
        journal: ja
            ? '静かな1日だった。多くは書かない。書けることだけ、そっと残しておく。'
            : 'A quiet day. Not much to say. Leaving only what wants to stay.',
        feedback: ja ? '今日は、それで充分。' : 'Today, that is enough.',
        titleSuggestion: ja ? '静かな1日' : 'Quiet',
      );
    }

    final journal = switch (personality) {
      AiPersonality.standard => ja
          ? '今日は穏やかな1日だった。午後は渋谷で打ち合わせをこなし、夕方はカフェで本を開く時間を持てた。歩数も悪くなく、よく動いた日と言える。'
          : 'A calm day. The afternoon meeting in Shibuya went smoothly, and the evening gave me time with a book at a cafe.',
      AiPersonality.mirroring => ja
          ? (voice.isNotEmpty
              ? 'なんだかんだ1日終わった。$voiceって感じ。打ち合わせもまあまあ進んだし、夜は自炊。悪くない。'
              : 'なんだかんだで1日終わった。打ち合わせもまあまあ進んだし、夜は自炊。悪くない。')
          : 'Day went by, you know? Meeting was alright, made dinner at home. Not bad.',
      AiPersonality.friendly => ja
          ? '今日もおつかれさま！午後の打ち合わせ、ちゃんと向き合えてえらかったね。夜の自炊も、自分のために手を動かせたのが素敵だなって思うよ。'
          : 'You did great today! That meeting in the afternoon — really proud of you for showing up. And cooking dinner at home? So sweet to yourself.',
    };

    final feedback = switch (personality) {
      AiPersonality.standard => ja ? '今日はよく歩いた一日でした。' : 'You moved well today.',
      AiPersonality.mirroring =>
        ja ? '今日もよくやったよ、自分。' : 'You did good today, you.',
      AiPersonality.friendly =>
        ja ? 'がんばったね、ゆっくり休んでね。' : "You did so well — rest up tonight.",
    };

    return AiGenerationResult(
      journal: journal,
      feedback: feedback,
      titleSuggestion: ja ? '静かな1日' : 'A quiet day',
    );
  }

  /// Cheap heuristic for the mock — a real provider does this with the LLM.
  _Mood _inferMood(String voice) {
    if (voice.isEmpty) return _Mood.neutral;
    const lowMarkers = [
      'つらい', 'しんどい', '疲れた', '無理', '泣', 'やめたい',
      'tired', 'exhausted', 'down', 'sad', "can't",
    ];
    final v = voice.toLowerCase();
    for (final m in lowMarkers) {
      if (v.contains(m)) return _Mood.low;
    }
    return _Mood.neutral;
  }
}

enum _Mood { low, neutral }
