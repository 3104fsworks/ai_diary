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
/// Throws [FreeQuotaExceeded] when a free user has already used today's
/// single generation. The UI catches this and shows the upgrade prompt.
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

  /// Developer-owned shared key.
  ///
  /// First tries the build-time --dart-define (preferred when CI can inject
  /// it cleanly), then falls back to the inline beta key so PowerShell quoting
  /// bugs don't silently downgrade us to Mock.
  ///
  /// TODO(beta-end): remove the inline key and move behind a backend proxy
  /// before public release. The repo is private, but a Gemini key inside an
  /// APK is still reverse-engineerable.
  static const _kInlineBetaGeminiKey =
      'AIzaSyA9XpRl6psRNS82ovHdGlrqQY6ssck3E8s';
  String get _sharedApiKey {
    const fromEnv =
        String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    return fromEnv.isNotEmpty ? fromEnv : _kInlineBetaGeminiKey;
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

    // Free: 1/day, personality forced to Standard.
    if (settings.freeGenerationUsedToday) {
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
    if (_sharedApiKey.isEmpty) {
      lastOutcome = AiGenerationOutcome.mock;
      return _mock.generateDiary(
        entry: entry,
        personality: personality,
        localeCode: localeCode,
        voiceTranscript: voiceTranscript,
      );
    }
    return _generateLive(
      key: _sharedApiKey,
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

/// Thrown when a free user has already used their daily generation.
class FreeQuotaExceeded implements Exception {
  const FreeQuotaExceeded();
}
