import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/ai/routing_ai_diary_service.dart';
import '../../core/export/sns_image_exporter.dart';
import '../../core/health/health_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/goal_item.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/section_label.dart';
import 'voice_recording_screen.dart';
import 'widgets/goal_grid.dart';
import 'widgets/particle_orb.dart';
import 'widgets/sns_image_card.dart';
import 'widgets/voice_tooltip.dart';

class DiaryEditScreen extends StatefulWidget {
  const DiaryEditScreen({super.key});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final _textController = TextEditingController();
  final _snsKey = GlobalKey();
  final _imagePicker = ImagePicker();

  String _rawVoiceMemo = '';
  List<String> _photoPaths = [];
  bool _saving = false;
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
    if (result == null || result.transcript.isEmpty) return;
    setState(() {
      final text = result.transcript;
      _rawVoiceMemo =
          _rawVoiceMemo.isEmpty ? text : '$_rawVoiceMemo\n$text';
      final cur = _textController.text;
      _textController.text = cur.isEmpty ? text : '$cur\n$text';
    });
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
      rawVoiceMemo: _rawVoiceMemo,
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
      // No artificial particle overlay — go straight from tap to save.
      final ai = await services.ai.generateDiary(
        entry: draft,
        personality: settings.effectivePersonality,
        localeCode: localeCode,
        voiceTranscript: _rawVoiceMemo,
      );

      final completed = draft.copyWith(
        aiTitle: ai.titleSuggestion,
        aiJournal: ai.journal,
        aiFeedback: ai.feedback,
      );
      await services.diary.save(completed);

      if (!mounted) return;
      setState(() => _saving = false);

      final outcome = services.ai.lastOutcome;
      final saveMessage = outcome == AiGenerationOutcome.fallback
          ? l.diaryAiFallback
          : l.diarySaved;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saveMessage), duration: const Duration(seconds: 2)),
      );
      context.pop();
    } on FreeQuotaExceeded {
      if (!mounted) return;
      setState(() => _saving = false);
      await _showUpgradeDialog();
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
      rawVoiceMemo: _rawVoiceMemo,
      photoPaths: _photoPaths,
      goals: _goals,
      activity: activity,
      weather: const WeatherInfo(
        kind: WeatherKind.sunny,
        tempC: 22,
        place: 'Tokyo',
      ),
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
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 4,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(hintText: l.diaryPlaceholder),
                ),
              ),
              const SizedBox(height: 12),
              _PhotoAddButton(
                label: l.diaryAddPhoto,
                count: _photoPaths.length,
                onTap: _addPhoto,
              ),
              if (_rawVoiceMemo.isNotEmpty) ...[
                SectionLabel(l.diaryRawVoice),
                _RawVoiceBlock(text: _rawVoiceMemo, hint: l.diaryRawVoiceHint),
              ],
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

class _RawVoiceBlock extends StatelessWidget {
  final String text;
  final String hint;
  const _RawVoiceBlock({required this.text, required this.hint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Text(hint, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
