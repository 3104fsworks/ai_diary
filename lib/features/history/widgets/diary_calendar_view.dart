import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/diary_entry.dart';

/// Minimal month calendar with a dot under days that have a diary entry.
/// Tap the dot to navigate.
class DiaryCalendarView extends StatefulWidget {
  final List<DiaryEntry> entries;
  final void Function(DiaryEntry entry) onTapEntry;

  const DiaryCalendarView({
    super.key,
    required this.entries,
    required this.onTapEntry,
  });

  @override
  State<DiaryCalendarView> createState() => _DiaryCalendarViewState();
}

class _DiaryCalendarViewState extends State<DiaryCalendarView> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  Map<int, DiaryEntry> _entriesByDay() {
    final result = <int, DiaryEntry>{};
    for (final e in widget.entries) {
      if (e.date.year == _month.year && e.date.month == _month.month) {
        result[e.date.day] = e;
      }
    }
    return result;
  }

  void _shift(int by) {
    setState(() {
      _month = DateTime(_month.year, _month.month + by);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final monthLabel =
        DateFormat.yMMMM(locale).format(_month);

    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    // Monday-first grid: shift Dart's weekday (1=Mon..7=Sun).
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday - 1;

    final entriesByDay = _entriesByDay();
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month header
          Row(
            children: [
              IconButton(
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left, size: 22),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday headers
          Row(
            children: [
              for (final w in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      w,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Day grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            children: [
              for (int i = 0; i < firstWeekday; i++) const SizedBox(),
              for (int d = 1; d <= daysInMonth; d++)
                _DayCell(
                  day: d,
                  isToday: today.year == _month.year &&
                      today.month == _month.month &&
                      today.day == d,
                  entry: entriesByDay[d],
                  onTap: entriesByDay[d] == null
                      ? null
                      : () => widget.onTapEntry(entriesByDay[d]!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isToday;
  final DiaryEntry? entry;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    required this.isToday,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEntry = entry != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
              color: hasEntry
                  ? theme.colorScheme.onSurface
                  : theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasEntry
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
