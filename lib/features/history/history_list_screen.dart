import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/service_locator.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/diary_entry.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/error_view.dart';
import 'widgets/diary_calendar_view.dart';

enum _ViewMode { list, calendar }

class HistoryListScreen extends StatefulWidget {
  const HistoryListScreen({super.key});

  @override
  State<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends State<HistoryListScreen> {
  Future<List<DiaryEntry>>? _entriesFuture;
  _ViewMode _mode = _ViewMode.list;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _entriesFuture ??= Services.of(context).diary.listEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final fresh = Services.of(context).diary.listEntries();
    setState(() => _entriesFuture = fresh);
    await fresh;
  }

  /// Case-insensitive substring match across title, journal, memo, voice.
  List<DiaryEntry> _filter(List<DiaryEntry> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((e) {
      final haystack = [
        e.aiTitle ?? '',
        e.aiJournal ?? '',
        e.userMemo,
        e.rawVoiceMemo,
        e.aiFeedback ?? '',
      ].join('\n').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(DiaryEntry e) async {
    final l = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(e.aiTitle ?? '—', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  formatDateHeader(e.date, Localizations.localeOf(ctx)),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Text(l.historyDeleteBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(l.historyDelete),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(l.commonCancel),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true || !mounted) return;
    await Services.of(context).diary.delete(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.historyDeleted)),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          IconButton(
            tooltip: _mode == _ViewMode.list ? l.calendarView : l.listView,
            icon: Icon(
              _mode == _ViewMode.list
                  ? Icons.calendar_month_outlined
                  : Icons.view_list_outlined,
              size: 22,
            ),
            onPressed: () => setState(() {
              _mode = _mode == _ViewMode.list
                  ? _ViewMode.calendar
                  : _ViewMode.list;
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar — only visible in list view (calendar shows by date).
          if (_mode == _ViewMode.list)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  color: theme.dividerColor.withValues(alpha: 0.35),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l.historySearchHint,
                          isCollapsed: true,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<DiaryEntry>>(
                future: _entriesFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const AppLoading();
                  }
                  if (snap.hasError) {
                    return ErrorView(onRetry: _refresh);
                  }
                  final entries = _filter(snap.data ?? const []);
                  final unfiltered = snap.data ?? const [];

                  if (unfiltered.isEmpty) {
                    return _EmptyState(
                      title: l.historyEmpty,
                      hint: l.historyEmptyHint,
                      ctaLabel: l.historyEmptyCta,
                      onTapCta: () => context.push(AppRoutes.diary),
                    );
                  }

                  if (_mode == _ViewMode.calendar) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: DiaryCalendarView(
                        entries: entries,
                        onTapEntry: (e) => context.push('/history/${e.id}'),
                      ),
                    );
                  }

                  if (entries.isEmpty) {
                    // Filter excluded everything.
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          '— ${l.historyEmpty}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      24 + MediaQuery.viewPaddingOf(context).bottom,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => Divider(
                      color: theme.dividerColor,
                      height: 1,
                      thickness: 0.5,
                    ),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return InkWell(
                        onTap: () => context.push('/history/${e.id}'),
                        onLongPress: () => _confirmDelete(e),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDateHeader(e.date, locale),
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                e.aiTitle ?? '—',
                                style: theme.textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String hint;
  final String ctaLabel;
  final VoidCallback onTapCta;

  const _EmptyState({
    required this.title,
    required this.hint,
    required this.ctaLabel,
    required this.onTapCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Opacity(
                    opacity: 0.55,
                    child: AppLogo(
                      size: 96,
                      coreColor: theme.textTheme.bodySmall?.color,
                      particleColor: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hint,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: onTapCta,
                      child: Text(ctaLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
