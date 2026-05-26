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
  final String journal;
  final String feedback;
  final String? titleSuggestion;
  const AiGenerationResult({
    required this.journal,
    required this.feedback,
    this.titleSuggestion,
  });
}
