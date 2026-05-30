import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../core/ai/radio_script_service.dart';
import '../../core/audio/tts_service.dart';
import '../../data/models/diary_entry.dart';
import '../../data/models/radio_episode.dart';
import '../../data/sources/local/radio_episode_store.dart';
import '../../features/diary/widgets/particle_orb.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/premium_upsell_sheet.dart';
import '../../widgets/app_loading.dart';
import 'radio_player_screen.dart';

/// Data passed via GoRouter `extra` when navigating to [RadioPlayerScreen].
class RadioPlayerArgs {
  final RadioEpisode episode;
  final List<RadioEpisode> all;
  const RadioPlayerArgs({required this.episode, required this.all});
}

/// Main AI radio hub screen.
///
/// Layout:
///   AppBar ← title 📅
///   PageView (swipe left = older, right = newer) of episode orbs
///   Page indicator dots
///
/// Each page is either:
///   • A generated episode  → tapping the orb opens [RadioPlayerScreen]
///   • A "generate" slot   → tapping triggers script + TTS generation
class WeeklyRadioScreen extends StatefulWidget {
  const WeeklyRadioScreen({super.key});

  @override
  State<WeeklyRadioScreen> createState() => _WeeklyRadioScreenState();
}

class _WeeklyRadioScreenState extends State<WeeklyRadioScreen> {
  List<RadioEpisode>? _episodes;
  List<DiaryEntry>? _diaryEntries;
  bool _loading = true;
  String? _generatingId; // episode id currently being generated

  late final PageController _pageCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────

  Future<void> _loadData() async {
    // Capture service reference before any async gap.
    final weeklySummary = Services.of(context).weeklySummary;

    final episodes = await RadioEpisodeStore.instance.loadAll();
    List<DiaryEntry> entries = [];
    try {
      entries = await weeklySummary.getLastSevenDays();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _episodes = episodes;
      _diaryEntries = entries;
      _loading = false;
    });

    // Jump to newest (last page) after layout.
    final slots = _buildSlots(episodes);
    if (slots.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageCtrl.hasClients) {
          final target = slots.length - 1;
          _pageCtrl.jumpToPage(target);
          setState(() => _currentPage = target);
        }
      });
    }

    // Auto-generate if generation is due.
    _maybeAutoGenerate(episodes, entries);
  }

  void _maybeAutoGenerate(
      List<RadioEpisode> episodes, List<DiaryEntry> entries) {
    if (entries.isEmpty) return;
    final now = DateTime.now();

    // Weekly (Sunday)
    if (RadioEpisodeStore.isWeeklyDue(now)) {
      final sunday = RadioEpisodeStore.lastSunday(now);
      final id = RadioEpisodeStore.weeklyId(sunday);
      if (!episodes.any((e) => e.id == id)) {
        _startGeneration(
          episodeId: id,
          type: RadioEpisodeType.weekly,
          entries: entries,
        );
      }
    }

    // Monthly (last day of month)
    if (RadioEpisodeStore.isMonthlyDue(now)) {
      final lastDay = RadioEpisodeStore.lastDayOfMonth(now);
      final id = RadioEpisodeStore.monthlyId(lastDay);
      if (!episodes.any((e) => e.id == id)) {
        // Load full month entries for monthly episode
        _startMonthlyGeneration(id);
      }
    }
  }

  Future<void> _startMonthlyGeneration(String episodeId) async {
    try {
      // For monthly, get the whole month's entries
      final now = DateTime.now();
      final firstDay = DateTime(now.year, now.month, 1);
      final monthEntries = await Services.of(context)
          .weeklySummary
          .getWeekEntries(firstDay);
      if (!mounted) return;
      _startGeneration(
        episodeId: episodeId,
        type: RadioEpisodeType.monthly,
        entries: monthEntries,
      );
    } catch (_) {}
  }

  // ── Premium gate ──────────────────────────────────────────────────────

  /// Returns true when the user may proceed. Shows [PremiumUpsellSheet] and
  /// returns false when the trial is over and no paid plan is active.
  Future<bool> _checkPremiumOrUpsell() async {
    if (!mounted) return false;
    final settings = AppSettingsScope.of(context);
    if (settings.isPremium) return true;
    await PremiumUpsellSheet.show(context);
    return false;
  }

  // ── Episode generation ────────────────────────────────────────────────

  Future<void> _startGeneration({
    required String episodeId,
    required RadioEpisodeType type,
    required List<DiaryEntry> entries,
  }) async {
    if (_generatingId != null) return; // already generating
    if (!await _checkPremiumOrUpsell()) return; // trial over / not paid
    if (!mounted) return;
    if (entries.isEmpty) {
      _showSnack('日記を書いてから生成できます');
      return;
    }
    setState(() => _generatingId = episodeId);

    try {
      final settings = AppSettingsScope.of(context);
      final locale = Localizations.localeOf(context).languageCode;

      // 1 — Script
      final scriptSvc = RadioScriptService(apiKey: settings.geminiApiKey);
      final script = await scriptSvc.generateScript(
        entries,
        locale: locale,
        episodeType: type,
        voiceType: settings.radioVoiceType,
        gender: settings.radioVoiceGender,
      );
      scriptSvc.dispose();
      if (!mounted) return;

      // 2 — TTS
      final audioPath = await RadioEpisodeStore.instance.audioPath(episodeId);
      final tts = TtsService(apiKey: settings.openAiApiKey);
      await tts.synthesizeTo(
        text: script,
        destPath: audioPath,
        voiceType: settings.radioVoiceType,
        gender: settings.radioVoiceGender,
      );
      tts.dispose();
      if (!mounted) return;

      // 3 — Save
      final episode = RadioEpisode(
        id: episodeId,
        generatedAt: DateTime.now(),
        type: type,
        script: script,
        audioFilePath: audioPath,
      );
      await RadioEpisodeStore.instance.save(episode);
      if (!mounted) return;

      final all = await RadioEpisodeStore.instance.loadAll();
      setState(() {
        _episodes = all;
        _generatingId = null;
      });

      // Jump to the new episode
      final slots = _buildSlots(all);
      final idx = slots.indexWhere((s) => s.episode?.id == episodeId);
      if (idx >= 0 && _pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          idx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _generatingId = null);
      _showSnack('生成に失敗しました: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Slots (pages) ─────────────────────────────────────────────────────

  /// Builds page slots: all saved episodes (oldest first) + optional
  /// "generate weekly" and/or "generate monthly" slots.
  List<_RadioSlot> _buildSlots(List<RadioEpisode> episodes) {
    final now = DateTime.now();
    final sorted = List<RadioEpisode>.from(episodes)
      ..sort((a, b) => a.generatedAt.compareTo(b.generatedAt));

    final slots = sorted.map((e) => _RadioSlot.episode(e)).toList();

    // Pending weekly slot
    final sunday = RadioEpisodeStore.lastSunday(now);
    final weeklyId = RadioEpisodeStore.weeklyId(sunday);
    if (!episodes.any((e) => e.id == weeklyId)) {
      slots.add(_RadioSlot.pending(weeklyId, RadioEpisodeType.weekly));
    }

    // Pending monthly slot (only on last day)
    if (RadioEpisodeStore.isMonthlyDue(now)) {
      final lastDay = RadioEpisodeStore.lastDayOfMonth(now);
      final monthlyId = RadioEpisodeStore.monthlyId(lastDay);
      if (!episodes.any((e) => e.id == monthlyId)) {
        slots.add(_RadioSlot.pending(monthlyId, RadioEpisodeType.monthly));
      }
    }

    // Always have at least one slot
    if (slots.isEmpty) {
      slots.add(_RadioSlot.pending(weeklyId, RadioEpisodeType.weekly));
    }

    return slots;
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.weeklyRadioTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 22),
            tooltip: 'カレンダー',
            onPressed: _showCalendarSheet,
          ),
        ],
      ),
      body: _loading
          ? const AppLoading()
          : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final episodes = _episodes ?? [];
    final slots = _buildSlots(episodes);
    // Clamp currentPage in case list shrunk
    final safePage = _currentPage.clamp(0, slots.length - 1);

    return Column(
      children: [
        // ── PageView ────────────────────────────────────────────────
        Expanded(
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: slots.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) {
              final slot = slots[i];
              return _EpisodePage(
                slot: slot,
                isGenerating: _generatingId == slot.id,
                onGenerate: () => _startGeneration(
                  episodeId: slot.id,
                  type: slot.type,
                  entries: _diaryEntries ?? [],
                ),
                onPlay: slot.episode != null
                    ? () => _openPlayer(slot.episode!)
                    : null,
              );
            },
          ),
        ),

        // ── Page indicator ───────────────────────────────────────────
        if (slots.length > 1)
          Padding(
            padding: EdgeInsets.only(
              bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            child: _PageDots(
              count: slots.length,
              current: safePage,
              slots: slots,
            ),
          )
        else
          SizedBox(height: 24 + MediaQuery.viewPaddingOf(context).bottom),
      ],
    );
  }

  void _openPlayer(RadioEpisode episode) {
    context.push(
      AppRoutes.radioPlayer,
      extra: RadioPlayerArgs(episode: episode, all: _episodes ?? [episode]),
    );
  }

  void _showCalendarSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, sc) => _RadioCalendarSheet(
          episodes: _episodes ?? [],
          diaryEntries: _diaryEntries ?? [],
          scrollController: sc,
          onSelectEpisode: (ep) {
            Navigator.pop(ctx);
            _openPlayer(ep);
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Slot model
// ─────────────────────────────────────────────────────────────────────────────

class _RadioSlot {
  final String id;
  final RadioEpisodeType type;
  final RadioEpisode? episode; // null = pending generation

  const _RadioSlot._({required this.id, required this.type, this.episode});

  factory _RadioSlot.episode(RadioEpisode ep) =>
      _RadioSlot._(id: ep.id, type: ep.type, episode: ep);

  factory _RadioSlot.pending(String id, RadioEpisodeType type) =>
      _RadioSlot._(id: id, type: type);

  bool get isReady => episode != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Episode page (one page in the PageView)
// ─────────────────────────────────────────────────────────────────────────────

class _EpisodePage extends StatelessWidget {
  final _RadioSlot slot;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final VoidCallback? onPlay;

  const _EpisodePage({
    required this.slot,
    required this.isGenerating,
    required this.onGenerate,
    required this.onPlay,
  });

  bool get _isMonthly => slot.type == RadioEpisodeType.monthly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = _isMonthly
        ? const Color(0xFFD4A853) // gold for monthly
        : theme.colorScheme.primary;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Monthly badge ─────────────────────────────────────────
          if (_isMonthly) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primary.withValues(alpha: 0.5)),
              ),
              child: Text(
                '✦ 月刊スペシャル ✦',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Orb ──────────────────────────────────────────────────
          GestureDetector(
            onTap: slot.isReady ? onPlay : (isGenerating ? null : onGenerate),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ParticleOrb(
                  size: 200,
                  intensity: slot.isReady ? 0.75 : (isGenerating ? 0.9 : 0.35),
                  color: primary,
                  converging: isGenerating,
                  particleCount: _isMonthly ? 120 : 90,
                ),
                if (isGenerating)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ── Action button ─────────────────────────────────────────
          if (isGenerating)
            Text(
              'ラジオを生成中…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            )
          else if (slot.isReady)
            _PillButton(
              label: 'ラジオを聞く',
              icon: Icons.play_arrow_rounded,
              color: primary,
              onTap: onPlay!,
            )
          else
            _PillButton(
              label: _isMonthly ? '月刊ラジオを生成する' : '今週のラジオを生成する',
              icon: Icons.radio_outlined,
              color: primary,
              onTap: onGenerate,
            ),
          const SizedBox(height: 16),

          // ── Date ─────────────────────────────────────────────────
          Text(
            _dateLabel(context),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context) {
    if (slot.episode != null) {
      final d = slot.episode!.generatedAt;
      return '${d.year}年${d.month}月${d.day}日生成';
    }
    return slot.isReady
        ? ''
        : (_isMonthly ? '今月の特別号' : '今週のエピソード');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill button
// ─────────────────────────────────────────────────────────────────────────────

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page dots indicator
// ─────────────────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final List<_RadioSlot> slots;

  const _PageDots({
    required this.count,
    required this.current,
    required this.slots,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        final slot = slots[i];
        final isMonthly = slot.type == RadioEpisodeType.monthly;
        final dotColor = isMonthly
            ? const Color(0xFFD4A853)
            : theme.colorScheme.primary;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: isActive
                ? dotColor
                : dotColor.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Calendar bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _RadioCalendarSheet extends StatefulWidget {
  final List<RadioEpisode> episodes;
  final List<DiaryEntry> diaryEntries;
  final ScrollController scrollController;
  final void Function(RadioEpisode) onSelectEpisode;

  const _RadioCalendarSheet({
    required this.episodes,
    required this.diaryEntries,
    required this.scrollController,
    required this.onSelectEpisode,
  });

  @override
  State<_RadioCalendarSheet> createState() => _RadioCalendarSheetState();
}

class _RadioCalendarSheetState extends State<_RadioCalendarSheet> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday - 1;

    // Build day lookup maps
    final diaryDays = <int>{};
    for (final e in widget.diaryEntries) {
      if (e.date.year == _month.year && e.date.month == _month.month) {
        diaryDays.add(e.date.day);
      }
    }
    // Also scan all stored entries if available
    final radioByDay = <int, RadioEpisode>{};
    for (final ep in widget.episodes) {
      final d = ep.generatedAt;
      if (d.year == _month.year && d.month == _month.month) {
        radioByDay[d.day] = ep;
      }
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        // Month nav
        Row(
          children: [
            IconButton(
              onPressed: () => _shift(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_month.year}年${_month.month}月',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shift(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Weekday headers
        Row(
          children: const ['月', '火', '水', '木', '金', '土', '日']
              .map(
                (w) => Expanded(
                  child: Center(
                    child: Text(w, style: const TextStyle(fontSize: 11)),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        // Day grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          children: [
            for (int i = 0; i < firstWeekday; i++) const SizedBox(),
            for (int d = 1; d <= daysInMonth; d++)
              _CalendarCell(
                day: d,
                hasDiary: diaryDays.contains(d),
                radioEpisode: radioByDay[d],
                isToday: DateTime.now().year == _month.year &&
                    DateTime.now().month == _month.month &&
                    DateTime.now().day == d,
                onTap: radioByDay[d] != null
                    ? () => widget.onSelectEpisode(radioByDay[d]!)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          children: [
            _LegendDot(
              color: theme.colorScheme.primary,
              label: '日記',
            ),
            const SizedBox(width: 16),
            const _LegendDot(
              color: Color(0xFF4DB6AC),
              label: '週刊ラジオ',
            ),
            const SizedBox(width: 16),
            const _LegendDot(
              color: Color(0xFFD4A853),
              label: '月刊スペシャル',
            ),
          ],
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  final int day;
  final bool hasDiary;
  final RadioEpisode? radioEpisode;
  final bool isToday;
  final VoidCallback? onTap;

  const _CalendarCell({
    required this.day,
    required this.hasDiary,
    required this.radioEpisode,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ep = radioEpisode;
    final radioColor = ep == null
        ? null
        : (ep.isMonthly ? const Color(0xFFD4A853) : const Color(0xFF4DB6AC));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Day number
          Container(
            width: 28,
            height: 28,
            decoration: radioColor != null
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    color: radioColor.withValues(alpha: 0.15),
                    border: Border.all(color: radioColor, width: 1.5),
                  )
                : null,
            child: Center(
              child: Text(
                '$day',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                  color: radioColor ??
                      (hasDiary
                          ? theme.colorScheme.onSurface
                          : theme.textTheme.bodySmall?.color
                              ?.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Diary dot
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasDiary
                  ? theme.colorScheme.primary.withValues(alpha: 0.7)
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
