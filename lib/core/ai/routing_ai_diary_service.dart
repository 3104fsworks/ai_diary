import '../../app/app_settings.dart';
import '../../data/models/ai_personality.dart';
import '../../data/models/diary_entry.dart';
import 'ai_diary_service.dart';
import 'gemini_ai_diary_service.dart';
import 'mock_ai_diary_service.dart';

/// Picks the real provider based on the plan-gating decision flow:
///
///   1. User has BYOK key   → use that key, unlimited, chosen personality
///   2. User is Premium     → shared API*, unlimited, chosen personality
///   3. Free user           → shared API*, 1/day, personality forced to Standard
///
/// (*) The "shared API" path uses the same Gemini service for now. When the
///     real shared backend ships, swap the `_sharedApiKey` source.
///
/// Throws [FreeQuotaExceeded] when a free user has used all 3 weekly AI
/// generations. The UI catches this and shows the premium upsell sheet.
class RoutingAiDiaryService implements AiDiaryService {
  RoutingAiDiaryService({required this.settings})
      : _mock = MockAiDiaryService();

  final AppSettings settings;
  final MockAiDiaryService _mock;

  AiGenerationOutcome? lastOutcome;
  /// Populated only when the live Gemini call threw — the UI surfaces a
  /// short prefix of this in the save SnackBar so beta testers can
  /// report back exactly why we fell back to Mock.
  String? lastErrorMessage;

  /// Developer-owned shared key (BYOK path only).
  ///
  /// In production the app routes through Firebase Functions (proxyBaseUrl
  /// set in settings), so no API key is needed in the Flutter binary.
  /// For local testing, set GEMINI_API_KEY via `--dart-define`.
  String get _sharedApiKey {
    const fromEnv =
        String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    return fromEnv;
  }

  @override
  Future<AiGenerationResult> generateDiary({
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  }) async {
    final byok = settings.geminiApiKey;
    final hasByok = byok.isNotEmpty;
    final premium = settings.isPremium;

    // Decision flow (highest priority first):
    if (hasByok) {
      final r = await _generateLive(
        key: byok,
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
      return r;
    }

    if (premium) {
      // Premium uses the shared dev key (when available) with chosen tone.
      return _generateSharedOrMock(
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
    }

    // Free: 3 times per rolling 7-day window, personality forced to Standard.
    if (settings.freeGenerationExceededThisWeek) {
      throw const FreeQuotaExceeded();
    }
    final result = await _generateSharedOrMock(
      entry: entry,
      personality: AiPersonality.standard,
      localeCode: localeCode,
      voiceTranscript: voiceTranscript,
    );
    await settings.markFreeGenerationUsed();
    return result;
  }

  Future<AiGenerationResult> _generateSharedOrMock({
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  }) async {
    // Use proxy if configured (production path), or direct key if available
    // (local dev with --dart-define=GEMINI_API_KEY=...).
    // Fall back to mock when neither is set.
    final hasProxy = settings.proxyBaseUrl.isNotEmpty;
    final hasKey = _sharedApiKey.isNotEmpty;
    if (!hasProxy && !hasKey) {
      lastOutcome = AiGenerationOutcome.mock;
      return _mock.generateDiary(
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
    }
    return _generateLive(
      key: _sharedApiKey, // empty when proxy handles auth
      entry: entry,
      personality: personality,
      localeCode: localeCode,
      voiceTranscript: voiceTranscript,
    );
  }

  Future<AiGenerationResult> _generateLive({
    required String key,
    required DiaryEntry entry,
    required AiPersonality personality,
    required String localeCode,
    String? voiceTranscript,
  }) async {
    final gemini = GeminiAiDiaryService(
      apiKey: key,
      proxyUrl: settings.proxyBaseUrl,
      appToken: settings.appProxyToken,
    );
    try {
      final r = await gemini.generateDiary(
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
      lastOutcome = AiGenerationOutcome.live;
      lastErrorMessage = null;
      return r;
    } catch (e) {
      lastOutcome = AiGenerationOutcome.fallback;
      lastErrorMessage = e.toString();
      return _mock.generateDiary(
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
    } finally {
      gemini.dispose();
    }
  }
}

enum AiGenerationOutcome { live, mock, fallback }

/// Thrown when a free user has used all 3 AI generations in the rolling
/// 7-day window.
class FreeQuotaExceeded implements Exception {
  const FreeQuotaExceeded();
}
