import '../../data/models/ai_personality.dart';
import '../../data/models/diary_entry.dart';

/// Abstract AI provider. Implementations: ClaudeService, GeminiService, OpenAiService.
/// Decoupled so the UI never sees provider details.
abstract class AiDiaryService {
  /// Generate the diary's Journal body and AI Feedback for [entry].
  /// [voiceTranscript] is the raw user speech, used for mirroring tone.
  Future<AiGenerationResult> generateDiary({
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  });
}

class AiGenerationResult {
  /// Full first-person diary body in Japanese.
  final String journal;

  /// Short AI comment in Japanese (may address "you").
  final String feedback;

  final String? titleSuggestion;

  /// 3-4 sentence English summary of the JP journal.
  /// Stored alongside the JP diary for AI Radio token efficiency.
  final String? journalEn;

  /// English translation of [feedback].
  final String? feedbackEn;

  /// Ultra-compact English bullet block for the AI Radio Index section.
  /// Typically two lines:
  ///   - **Core Action:** …
  ///   - **AI Sentiment:** keyword1, keyword2
  final String? radioIndex;

  const AiGenerationResult({
    required this.journal,
    required this.feedback,
    this.titleSuggestion,
    this.journalEn,
    this.feedbackEn,
    this.radioIndex,
  });
}
