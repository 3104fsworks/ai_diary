import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/export/diary_markdown_exporter.dart';
import '../../core/export/sns_image_exporter.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/diary_entry.dart';
import '../../features/diary/widgets/sns_image_card.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/error_view.dart';
import '../../widgets/section_label.dart';

class HistoryDetailScreen extends StatefulWidget {
  final String entryId;
  const HistoryDetailScreen({super.key, required this.entryId});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  Future<DiaryEntry?>? _entryFuture;
  DiaryEntry? _entry;
  final _snsKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entryFuture ??=
        Services.of(context).diary.getById(widget.entryId).then((e) {
      _entry = e;
      return e;
    });
  }

  Future<void> _export(DiaryEntry e) async {
    await DiaryMarkdownExporter.share(e);
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.exportShared)),
    );
  }

  Future<void> _shareSns(DiaryEntry e) async {
    try {
      await SnsImageExporter.share(
        boundaryKey: _snsKey,
        filename:
            'ai-diary-${e.date.toIso8601String().substring(0, 10)}.png',
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SNS image: $err')),
      );
    }
  }

  Future<void> _confirmDelete(DiaryEntry e) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.historyDeleteConfirm),
        content: Text(l.historyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.historyDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await Services.of(context).diary.delete(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.historyDeleted)),
    );
    Navigator.of(context).pop();
  }

  Future<void> _saveJournalEdit(String edited) async {
    final original = _entry;
    if (original == null) return;
    final updated = original.copyWith(aiJournal: edited);
    await Services.of(context).diary.save(updated);
    _entry = updated;
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.diaryJournalSavedEdit),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_entry != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 22),
              onSelected: (v) {
                if (v == 'delete' && _entry != null) _confirmDelete(_entry!);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l.historyDelete,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: FutureBuilder<DiaryEntry?>(
        future: _entryFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const AppLoading();
          }
          if (snap.hasError) {
            return const ErrorView();
          }
          final e = snap.data;
          if (e == null) {
            return Center(child: Text(l.historyEmpty));
          }
          return Stack(
            children: [
              // Off-screen capture target for the SNS image.
              Positioned(
                left: -SnsImageCard.width - 100,
                top: 0,
                child: RepaintBoundary(
                  key: _snsKey,
                  child: SnsImageCard(entry: e),
                ),
              ),
              ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              40 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Text(
                formatDateHeader(e.date, locale),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(e.aiTitle ?? '—', style: theme.textTheme.displayLarge),
              SectionLabel(l.diaryJournal),
              _InlineEditableJournal(
                initial: e.aiJournal ?? '',
                editHint: l.diaryJournalEditHint,
                onSave: _saveJournalEdit,
              ),
              if (e.audioFilePath != null &&
                  File(e.audioFilePath!).existsSync())
                _VoicePlaybackTile(
                  filePath: e.audioFilePath!,
                  durationSeconds: e.audioDurationSeconds,
                  playLabel: l.historyVoicePlay,
                  playingLabel: l.historyVoicePlaying,
                  pauseLabel: l.historyVoicePause,
                ),
              if (e.rawVoiceMemo.isNotEmpty)
                _RawVoiceCollapsible(
                  text: e.rawVoiceMemo,
                  hint: l.diaryRawVoiceHint,
                  showLabel: l.diaryRawVoiceShow,
                  hideLabel: l.diaryRawVoiceHide,
                ),
              if (e.photoPaths.isNotEmpty) ...[
                SectionLabel(l.diaryPhotos),
                _PhotoGrid(paths: e.photoPaths),
              ],
              if (e.activity != null) ...[
                SectionLabel(l.diaryActivity),
                Text(
                  '${e.activity!.steps} steps  ·  '
                  '${e.activity!.sleepHours.toStringAsFixed(1)} h sleep',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (e.aiFeedback != null) ...[
                const SizedBox(height: 28),
                Divider(color: theme.dividerColor, height: 1, thickness: 0.5),
                SectionLabel(l.diaryAIFeedback),
                Text(e.aiFeedback!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => _export(e),
                icon: const Icon(Icons.description_outlined, size: 20),
                label: Text(l.exportMarkdown),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _shareSns(e),
                icon: const Icon(Icons.ios_share_outlined, size: 20),
                label: Text(l.diaryShareSNS),
              ),
            ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Tap the journal text → keyboard pops up → edit inline → auto-save on blur.
class _InlineEditableJournal extends StatefulWidget {
  final String initial;
  final String editHint;
  final ValueChanged<String> onSave;

  const _InlineEditableJournal({
    required this.initial,
    required this.editHint,
    required this.onSave,
  });

  @override
  State<_InlineEditableJournal> createState() => _InlineEditableJournalState();
}

class _InlineEditableJournalState extends State<_InlineEditableJournal> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);
  final FocusNode _focus = FocusNode();
  late String _lastSaved = widget.initial;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) {
      final v = _controller.text;
      if (v != _lastSaved) {
        _lastSaved = v;
        widget.onSave(v);
      }
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focus,
          maxLines: null,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
          cursorColor: theme.colorScheme.primary,
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: widget.editHint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          onEditingComplete: () => _focus.unfocus(),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Text(widget.editHint, style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<String> paths;
  const _PhotoGrid({required this.paths});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            onTap: () => _openPhoto(context, paths, i),
            child: Hero(
              tag: 'photo-${paths[i]}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.file(
                  File(paths[i]),
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 96,
                    height: 96,
                    color: theme.dividerColor.withValues(alpha: 0.4),
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static void _openPhoto(
    BuildContext context,
    List<String> paths,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) =>
            _PhotoLightbox(paths: paths, initialIndex: initialIndex),
      ),
    );
  }
}

/// Tap-to-close, pinch-to-zoom photo viewer.
class _PhotoLightbox extends StatefulWidget {
  final List<String> paths;
  final int initialIndex;
  const _PhotoLightbox({required this.paths, required this.initialIndex});

  @override
  State<_PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<_PhotoLightbox> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.paths.length,
              itemBuilder: (_, i) {
                return Hero(
                  tag: 'photo-${widget.paths[i]}',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.file(File(widget.paths[i])),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RawVoiceCollapsible extends StatefulWidget {
  final String text;
  final String hint;
  final String showLabel;
  final String hideLabel;

  const _RawVoiceCollapsible({
    required this.text,
    required this.hint,
    required this.showLabel,
    required this.hideLabel,
  });

  @override
  State<_RawVoiceCollapsible> createState() => _RawVoiceCollapsibleState();
}

class _RawVoiceCollapsibleState extends State<_RawVoiceCollapsible> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => _open = !_open),
            icon: Icon(
              _open
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 18,
            ),
            label: Text(_open ? widget.hideLabel : widget.showLabel),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.7,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.hint, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
            crossFadeState: _open
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

/// Compact audio playback bar shown in the history detail when a voice
/// recording file exists on disk.
class _VoicePlaybackTile extends StatefulWidget {
  final String filePath;
  final int? durationSeconds;
  final String playLabel;
  final String playingLabel;
  final String pauseLabel;

  const _VoicePlaybackTile({
    required this.filePath,
    required this.durationSeconds,
    required this.playLabel,
    required this.playingLabel,
    required this.pauseLabel,
  });

  @override
  State<_VoicePlaybackTile> createState() => _VoicePlaybackTileState();
}

class _VoicePlaybackTileState extends State<_VoicePlaybackTile> {
  final _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    if (widget.durationSeconds != null) {
      _total = Duration(seconds: widget.durationSeconds!);
    }
    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _state = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.filePath));
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = _state == PlayerState.playing;
    final progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _toggle,
              icon: Icon(
                isPlaying ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 32,
              ),
              tooltip: isPlaying ? widget.pauseLabel : widget.playLabel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_fmt(_position)} / ${_fmt(_total)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
