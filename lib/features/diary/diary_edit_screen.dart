import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ai/ai_diary_service.dart';
import '../../core/ai/routing_ai_diary_service.dart';
import '../../core/export/sns_image_exporter.dart';
import '../../core/health/health_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/goal_item.dart';
import '../../data/models/voice_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/section_label.dart';
import 'voice_recording_screen.dart';
import 'widgets/goal_grid.dart';
import 'widgets/particle_orb.dart';
import 'widgets/sns_image_card.dart';
import '../../core/notifications/time_capsule_service.dart';
import 'widgets/voice_tooltip.dart';

class DiaryEditScreen extends StatefulWidget {
  const DiaryEditScreen({super.key});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final _textController = TextEditingController();

  /// Editable controller for the "ありのままのつぶやき" section.
  /// Pre-filled from voice transcripts; user can also type here directly.
  /// Saved verbatim as [DiaryEntry.rawVoiceMemo] — never AI-rewritten.
  final _rawVoiceController = TextEditingController();

  final _snsKey = GlobalKey();
  final _imagePicker = ImagePicker();

  List<String> _photoPaths = [];
  bool _saving = false;

  /// Local path to the audio file produced by the last recording session.
  /// Stored in the diary entry so history can offer playback.
  String? _audioFilePath;

  /// Voice characteristics of the latest recording.
  /// Stored in the diary entry for weekly AI radio BGM selection.
  VoiceMetadata? _voiceMetadata;
  bool _showVoiceTooltip = false;
  bool _goalsLoaded = false;
  List<GoalItem> _goals = [];

  List<ScheduleItem> _schedule = const [];
  List<String> _doneTasks = const [];
  bool _calendarLoaded = false;
  bool _tasksLoaded = false;
  List<TimelineStop> _timeline = const [];
  bool _timelineLoaded = false;
  HealthSnapshot? _health;
  bool _healthLoaded = false;

  /// Set after _summariseIntoTextField finishes. Holds the AI-polished
  /// version so we don't pay for a second AI call at save time.
  AiGenerationResult? _aiPreview;
  bool _summarising = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = AppSettingsScope.of(context);
    if (!_goalsLoaded) {
      _goalsLoaded = true;
      _goals = settings.customGoals;
      // First-ever visit → show the voice tooltip.
      if (!settings.hasSeenVoiceTooltip) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showVoiceTooltip = true);
        });
      }
    }
    if (!_timelineLoaded) {
      _timelineLoaded = true;
      final services = Services.of(context);
      final today = DateTime.now();
      services.timeline
          .getStays(DateTime(today.year, today.month, today.day))
          .then((stays) {
        if (mounted) setState(() => _timeline = stays);
      });
    }
    if (!_healthLoaded) {
      _healthLoaded = true;
      final services = Services.of(context);
      if (settings.healthEnabled && services.health.isSupported) {
        services.health.getTodaySnapshot().then((snap) {
          if (mounted) setState(() => _health = snap);
        });
      }
    }
    if (!_calendarLoaded) {
      _calendarLoaded = true;
      final services = Services.of(context);
      if (settings.calendarEnabled) {
        services.calendar.getEventsFor(DateTime.now()).then((events) {
          if (mounted) setState(() => _schedule = events);
        });
      }
    }
    if (!_tasksLoaded) {
      _tasksLoaded = true;
      final services = Services.of(context);
      if (settings.tasksEnabled) {
        services.tasks.getCompletedTasksFor(DateTime.now()).then((done) {
          if (mounted) setState(() => _doneTasks = done);
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _rawVoiceController.dispose();
    super.dispose();
  }

  Future<void> _openVoiceMode() async {
    // Dismiss the first-time tooltip on the user's first tap.
    if (_showVoiceTooltip) {
      _dismissVoiceTooltip();
    }
    final result = await Navigator.of(context).push<VoiceRecordingResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const VoiceRecordingScreen(),
      ),
    );
    if (result == null) return;

    // Always capture audio metadata — even when transcription failed the audio
    // file exists and should be stored for history playback / time-capsule.
    if (result.audioFilePath != null) _audioFilePath = result.audioFilePath;
    if (result.voiceMetadata != null) _voiceMetadata = result.voiceMetadata;

    if (result.transcript.isEmpty) return;
    setState(() {
      final text = result.transcript;
      // Append to the raw voice controller (user can edit this section).
      final existing = _rawVoiceController.text;
      _rawVoiceController.text =
          existing.isEmpty ? text : '$existing\n$text';
      // Drop the raw transcript into the main text field as a placeholder so
      // the user sees *something* while the AI summary is being generated.
      final cur = _textController.text;
      _textController.text = cur.isEmpty ? text : '$cur\n$text';
    });
    // Then immediately ask the AI to rewrite that placeholder as a proper
    // first-person diary entry. The user can still edit afterwards.
    await _summariseIntoTextField();
  }

  /// Calls the AI right after voice input ends and replaces the text field
  /// with the polished first-person diary entry. The polished version is
  /// cached in [_aiPreview] so [_onDone] doesn't have to call the AI again.
  Future<void> _summariseIntoTextField() async {
    final rawText = _rawVoiceController.text.trim();
    if (rawText.isEmpty) return;
    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    final l = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    setState(() => _summarising = true);
    try {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day);
      final activity = _health == null
          ? null
          : ActivityInfo(
              steps: _health!.steps ?? 0,
              sleepHours: _health!.sleepHours ?? 0,
            );
      final draft = DiaryEntry(
        id: 'preview-${date.toIso8601String().substring(0, 10)}',
        date: date,
        userMemo: '',
        rawVoiceMemo: rawText,
        photoPaths: _photoPaths,
        goals: _goals,
        schedule: _schedule,
        doneTasks: _doneTasks,
        timeline: _timeline,
        activity: activity,
        audioFilePath: _audioFilePath,
        voiceMetadata: _voiceMetadata,
      );

      final ai = await services.ai.generateDiary(
        entry: draft,
        personality: settings.effectivePersonality,
        localeCode: localeCode,
        voiceTranscript: rawText,
      );

      if (!mounted) return;
      final outcome = services.ai.lastOutcome;
      if (outcome == AiGenerationOutcome.live) {
        // Real Gemini reply — drop the polished version into the field.
        setState(() {
          _aiPreview = ai;
          _textController.text = ai.journal;
        });
      } else {
        // Mock or fallback — keep the user's raw transcript in the text
        // box (we already placed it there) and tell them the AI failed.
        // Mock content like "夜の自炊" must NEVER leak into the journal.
        final err = services.ai.lastErrorMessage;
        final detail = (err != null && err.isNotEmpty)
            ? '\n${err.length > 120 ? '${err.substring(0, 120)}…' : err}'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI要約に失敗しました（[${outcome?.name}]）$detail'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on FreeQuotaExceeded {
      if (!mounted) return;
      await _showUpgradeDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.diaryAiFallback}\n$e')),
      );
    } finally {
      if (mounted) setState(() => _summarising = false);
    }
  }

  void _dismissVoiceTooltip() {
    setState(() => _showVoiceTooltip = false);
    AppSettingsScope.of(context).markVoiceTooltipSeen();
  }

  Future<void> _addPhoto() async {
    final remaining = 3 - _photoPaths.length;
    if (remaining <= 0) return;
    try {
      // pickMultiImage lets the user select several photos at once;
      // we then trim to the remaining slots (max 3 total).
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
        limit: remaining,
      );
      if (picked.isEmpty) return;
      final additions = picked.take(remaining).map((x) => x.path).toList();
      setState(() => _photoPaths = [..._photoPaths, ...additions]);
    } catch (_) {/* swallowed */}
  }

  Future<void> _shareSnsImage() async {
    try {
      await SnsImageExporter.share(
        boundaryKey: _snsKey,
        filename: 'ai-journal-${DateTime.now().millisecondsSinceEpoch}.png',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SNS image: $e')),
      );
    }
  }

  Future<void> _onDone() async {
    final services = Services.of(context);
    final settings = AppSettingsScope.of(context);
    final l = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    setState(() => _saving = true);

    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final activity = _health == null
        ? null
        : ActivityInfo(
            steps: _health!.steps ?? 0,
            sleepHours: _health!.sleepHours ?? 0,
          );
    final draft = DiaryEntry(
      id: 'd-${date.toIso8601String().substring(0, 10)}',
      date: date,
      userMemo: _textController.text,
      rawVoiceMemo: _rawVoiceController.text,
      photoPaths: _photoPaths,
      goals: _goals,
      schedule: _schedule,
      doneTasks: _doneTasks,
      timeline: _timeline,
      activity: activity,
      weather: const WeatherInfo(
        kind: WeatherKind.sunny,
        tempC: 22,
        place: 'Tokyo',
      ),
    );

    try {
      // The text field is now the source of truth for the journal body —
      // the user may have hand-edited the AI summary we dropped in earlier.
      // We only round-trip back to the AI when there's NO preview yet
      // (e.g. the user typed instead of dictating).
      final edited = _textController.text.trim();
      AiGenerationResult ai;
      if (_aiPreview != null && edited.isNotEmpty) {
        // Honour the user's edits as the final journal body. Title/feedback
        // (and all bilingual fields) come from the cached AI preview so we
        // don't re-bill the API.
        ai = AiGenerationResult(
          journal: edited,
          feedback: _aiPreview!.feedback,
          titleSuggestion: _aiPreview!.titleSuggestion,
          journalEn: _aiPreview!.journalEn,
          feedbackEn: _aiPreview!.feedbackEn,
          radioIndex: _aiPreview!.radioIndex,
        );
      } else {
        // Cold path: no preview, no voice input, or empty field → ask the
        // AI to compose from scratch using whatever the user did type.
        ai = await services.ai.generateDiary(
          entry: draft,
          personality: settings.effectivePersonality,
          localeCode: localeCode,
          voiceTranscript: _rawVoiceController.text,
        );
      }

      final completed = draft.copyWith(
        aiTitle: ai.titleSuggestion,
        aiJournal: ai.journal,
        aiJournalEn: ai.journalEn,
        aiFeedback: ai.feedback,
        aiFeedbackEn: ai.feedbackEn,
        aiRadioIndex: ai.radioIndex,
        audioFilePath: _audioFilePath,
        audioDurationSeconds: _voiceMetadata?.totalDurationSeconds,
        voiceMetadata: _voiceMetadata,
      );
      await services.diary.save(completed);

      // Schedule time-capsule notification if a delivery date is set.
      final capsule = completed.capsuleDeliveryDate;
      if (capsule != null && capsule.isAfter(DateTime.now())) {
        await TimeCapsuleService.instance.schedule(
          entryId: completed.id,
          deliveryDate: capsule,
          title: l.timeCapsuleNotifTitle,
          body: l.timeCapsuleNotifBody(
            completed.aiTitle ?? completed.userMemo.substring(
              0, completed.userMemo.length.clamp(0, 40)),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _saving = false);

      final outcome = services.ai.lastOutcome;
      final baseMessage = outcome == AiGenerationOutcome.fallback
          ? l.diaryAiFallback
          : l.diarySaved;
      // Debug tag — visible only in debug builds.
      final outcomeTag = kDebugMode
          ? switch (outcome) {
              AiGenerationOutcome.live => ' [LIVE]',
              AiGenerationOutcome.mock => ' [MOCK]',
              AiGenerationOutcome.fallback => ' [FALLBACK]',
              null => '',
            }
          : '';
      // On fallback, show the first 120 chars of the underlying error so
      // testers can report the root cause (bad key, blocked model, etc.).
      final err = services.ai.lastErrorMessage;
      final errSuffix = (outcome == AiGenerationOutcome.fallback &&
              err != null &&
              err.isNotEmpty)
          ? '\n${err.length > 120 ? '${err.substring(0, 120)}…' : err}'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$baseMessage$outcomeTag$errSuffix'),
          duration: const Duration(seconds: 8),
        ),
      );
      context.pop();
    } on FreeQuotaExceeded {
      // Quota exceeded — still save the diary using the raw text so the
      // user doesn't lose their entry, then show the upgrade prompt.
      if (!mounted) return;
      final completed = draft.copyWith(
        aiJournal: _textController.text.trim().isNotEmpty
            ? _textController.text.trim()
            : _rawVoiceController.text,
        audioFilePath: _audioFilePath,
        audioDurationSeconds: _voiceMetadata?.totalDurationSeconds,
        voiceMetadata: _voiceMetadata,
      );
      await services.diary.save(completed);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.diarySaved)),
      );
      await _showUpgradeDialog();
      if (!mounted) return;
      context.pop();
    }
  }

  Future<void> _showUpgradeDialog() async {
    final l = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.quotaTitle),
          content: Text(l.quotaBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.quotaLater),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push(AppRoutes.plan);
              },
              child: Text(l.quotaUpgrade),
            ),
          ],
        );
      },
    );
  }

  DiaryEntry _draftSnapshot() {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final activity = _health == null
        ? null
        : ActivityInfo(
            steps: _health!.steps ?? 0,
            sleepHours: _health!.sleepHours ?? 0,
          );
    return DiaryEntry(
      id: 'draft-${date.toIso8601String().substring(0, 10)}',
      date: date,
      userMemo: _textController.text,
      rawVoiceMemo: _rawVoiceController.text,
      photoPaths: _photoPaths,
      goals: _goals,
      activity: activity,
      weather: const WeatherInfo(
        kind: WeatherKind.sunny,
        tempC: 22,
        place: 'Tokyo',
      ),
      audioFilePath: _audioFilePath,
      voiceMetadata: _voiceMetadata,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final settings = AppSettingsScope.of(context);
    final now = DateTime.now();

    return Scaffold(
      // New header: date + weather/temp inline (title), Done button top-right.
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Flexible(
              child: Text(
                formatDateLong(now, locale),
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.wb_sunny_outlined,
              size: 16,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              formatTemperature(22, locale),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
            child: ElevatedButton(
              onPressed: _saving ? null : _onDone,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 38),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
              ),
              child: Text(l.diaryDone),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              200 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _textController,
                      // null = grow with content. minLines keeps the field
                      // from collapsing too small when empty.
                      maxLines: null,
                      minLines: 4,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge,
                      decoration:
                          InputDecoration(hintText: l.diaryPlaceholder),
                      onChanged: (value) {
                        // When the user clears the polished journal, also
                        // clear the raw voice section — they belong together
                        // as a single user-controlled draft.
                        if (value.trim().isEmpty &&
                            _rawVoiceController.text.isNotEmpty) {
                          setState(() {
                            _rawVoiceController.text = '';
                            _aiPreview = null;
                          });
                        }
                      },
                    ),
                    if (_summarising)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AIが要約中…',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _PhotoAddButton(
                label: l.diaryAddPhoto,
                count: _photoPaths.length,
                onTap: _addPhoto,
              ),
              // "ありのままのつぶやき" — always visible and editable.
              // Pre-filled from voice transcript; user can also type here.
              SectionLabel(l.diaryRawVoice),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _rawVoiceController,
                builder: (ctx, value, child) => _EditableRawVoiceBlock(
                  controller: _rawVoiceController,
                  hint: l.diaryRawVoiceHint,
                  // Show "AI再生成" only when there is text to summarise.
                  onAiRegenerate:
                      value.text.trim().isNotEmpty && !_summarising
                          ? _summariseIntoTextField
                          : null,
                ),
              ),
              SectionLabel(l.diaryDailyGoals),
              GoalGrid(
                goals: _goals,
                labelOf: (g) => goalDisplayLabel(context, g),
                onToggle: (i) => setState(() {
                  _goals = List.of(_goals);
                  _goals[i] = _goals[i].copyWith(checked: !_goals[i].checked);
                }),
              ),
              if (_health != null && !_health!.isEmpty) ...[
                SectionLabel(l.diaryActivity),
                _ActivityRow(
                  steps: _health!.steps,
                  sleepHours: _health!.sleepHours,
                ),
              ],
              if (settings.calendarEnabled) ...[
                SectionLabel(l.diarySchedule),
                if (_schedule.isEmpty)
                  Text(
                    l.diaryEmptySchedule,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  )
                else
                  ..._schedule.map((s) => _BulletLine(
                        leading: s.time ?? '',
                        text: s.title,
                      )),
              ],
              if (settings.tasksEnabled && _doneTasks.isNotEmpty) ...[
                SectionLabel(l.diaryDoneTasks),
                ..._doneTasks.map(
                  (t) => _BulletLine(leading: '✓', text: t),
                ),
              ],
              if (_timeline.isNotEmpty) ...[
                SectionLabel(l.diaryTimeline),
                ..._timeline.map((s) => _BulletLine(
                      leading: s.time,
                      text: s.place,
                    )),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: _shareSnsImage,
                icon: const Icon(Icons.ios_share_outlined, size: 20),
                label: Text(l.diaryShareSNS),
              ),
            ],
          ),

          // Bottom-centre cluster: ONLY the voice button (plus its tooltip
          // for first-time users, and the live waveform while listening).
          // Padding accounts for the Android navigation bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showVoiceTooltip)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VoiceTooltip(
                      title: l.diaryVoiceTooltipTitle,
                      body: l.diaryVoiceTooltipBody,
                      onDismiss: _dismissVoiceTooltip,
                    ),
                  ),
                _VoiceFab(onTap: _openVoiceMode),
              ],
            ),
          ),

          // (Particle saving overlay removed — completion is now instant.)

          Positioned(
            left: -SnsImageCard.width - 100,
            top: 0,
            child: RepaintBoundary(
              key: _snsKey,
              child: SnsImageCard(entry: _draftSnapshot()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoAddButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;
  const _PhotoAddButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_a_photo_outlined, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
            if (count > 0)
              Text('$count / 3', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Big, accent-coloured circular voice button — the diary's hero action.
/// A persistent particle halo gently breathes behind it to telegraph
/// "this is where you speak". Tap opens the fullscreen focus mode.
class _VoiceFab extends StatelessWidget {
  final VoidCallback onTap;
  const _VoiceFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: ParticleOrb(
              size: 110,
              intensity: 0.55,
              color: theme.colorScheme.primary,
              particleCount: 40,
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              elevation: 0,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Icon(
                  Icons.mic_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final String leading;
  final String text;
  const _BulletLine({required this.leading, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(leading, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final int? steps;
  final double? sleepHours;
  const _ActivityRow({required this.steps, required this.sleepHours});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final stepsText = steps == null ? l.diaryActivityDash : '$steps';
    final sleepText = sleepHours == null
        ? l.diaryActivityDash
        : l.diaryActivityHours(sleepHours!.toStringAsFixed(1));
    return Row(
      children: [
        Expanded(
          child: _Stat(
            icon: Icons.directions_walk_outlined,
            label: l.diaryActivitySteps,
            value: stepsText,
          ),
        ),
        Container(width: 1, height: 36, color: theme.dividerColor),
        Expanded(
          child: _Stat(
            icon: Icons.bedtime_outlined,
            label: l.diaryActivitySleep,
            value: sleepText,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Editable "ありのままのつぶやき" block.
///
/// Pre-filled with the voice transcript; user can edit, correct, or add
/// notes by typing.  Changes update [controller] immediately.
/// When [onAiRegenerate] is non-null, a small "AI再生成" button appears so
/// the user can ask the AI to re-polish the main journal after editing their
/// raw notes.
class _EditableRawVoiceBlock extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback? onAiRegenerate;

  const _EditableRawVoiceBlock({
    required this.controller,
    required this.hint,
    this.onAiRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'あなたの声・言葉そのままです。AI日記には反映されません。',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (onAiRegenerate != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onAiRegenerate,
                  child: Text(
                    'AI再生成',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
