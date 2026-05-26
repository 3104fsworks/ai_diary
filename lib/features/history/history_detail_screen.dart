import 'dart:async';
import 'dart:io';

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
