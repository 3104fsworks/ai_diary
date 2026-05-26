import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/diary_entry.dart';

/// Editorial-minimal 9:16 SNS card.
/// Logical size: 1080 x 1920. Rendered into a PNG via RepaintBoundary.
///
/// Design language: stoic, off-white background, charcoal text, generous
/// margins, magazine-style small-caps section labels. Only the bottom-right
/// "AI · DIARY" wordmark hints at the app — no QR code, no big logo.
class SnsImageCard extends StatelessWidget {
  static const double width = 1080;
  static const double height = 1920;

  final DiaryEntry entry;
  final List<String>? highlightsOverride;

  const SnsImageCard({
    super.key,
    required this.entry,
    this.highlightsOverride,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy.MM.dd').format(entry.date);
    final dow = DateFormat('E', 'en_US').format(entry.date).toUpperCase();
    final place = entry.weather?.place ?? '';

    final checkedGoals =
        entry.goals.where((g) => g.checked).take(3).toList(growable: false);

    final highlights = (highlightsOverride ?? _splitHighlights(entry))
        .where((s) => s.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: const Color(0xFFFAFAF7), // warm off-white
        child: Padding(
          padding: const EdgeInsets.fromLTRB(96, 120, 96, 96),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'Arial',
              color: Color(0xFF1A1A1A),
              fontSize: 36,
              height: 1.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  date: '$dateText  ·  $dow',
                  place: place,
                ),
                const SizedBox(height: 72),
                const _Hairline(),
                const SizedBox(height: 96),

                _SectionLabel(label: "TODAY'S GOALS"),
                const SizedBox(height: 36),
                for (final g in checkedGoals)
                  _BulletRow(
                    glyph: '✓',
                    text: _goalText(g.labelKey),
                  ),

                const SizedBox(height: 96),
                _SectionLabel(label: 'DAILY HIGHLIGHTS'),
                const SizedBox(height: 36),
                for (final h in highlights)
                  _BulletRow(glyph: '·', text: h),

                const Spacer(),

                if (entry.activity != null) ...[
                  _SectionLabel(label: 'STATS'),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      _StatChip(
                        value: NumberFormat('#,###').format(
                          entry.activity!.steps,
                        ),
                        label: 'STEPS',
                      ),
                      const SizedBox(width: 48),
                      _StatChip(
                        value:
                            '${entry.activity!.sleepHours.toStringAsFixed(1)}h',
                        label: 'SLEEP',
                      ),
                    ],
                  ),
                  const SizedBox(height: 64),
                ],

                const _Hairline(),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'AI  ·  DIARY',
                    style: const TextStyle(
                      fontFamily: 'Arial',
                      color: Color(0xFF757575),
                      fontSize: 26,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _goalText(String key) => switch (key) {
        'goalSteps' => 'Walk 5,000 steps',
        'goalNoMoney' => 'No spending today',
        'goalThanks' => 'Say "Thank you"',
        'goalSmile' => 'Smile at someone',
        'goalRead' => 'Read 10 pages',
        'goalSleep' => 'Sleep before midnight',
        _ => key,
      };

  static List<String> _splitHighlights(DiaryEntry e) {
    final src = (e.aiJournal != null && e.aiJournal!.isNotEmpty)
        ? e.aiJournal!
        : e.userMemo;
    if (src.isEmpty) return const [];
    // Break on Japanese sentence enders and Latin '.'.
    final parts = src.split(RegExp(r'(?<=[。．\.！!？\?])'));
    return parts.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }
}

class _Header extends StatelessWidget {
  final String date;
  final String place;
  const _Header({required this.date, required this.place});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          date,
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 38,
            letterSpacing: 2,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        if (place.isNotEmpty)
          Text(
            place.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 32,
              letterSpacing: 4,
              color: Color(0xFF757575),
            ),
          ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: const Color(0xFFD8D6D1),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Arial',
        fontSize: 28,
        letterSpacing: 5,
        color: Color(0xFF757575),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String glyph;
  final String text;
  const _BulletRow({required this.glyph, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              glyph,
              style: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 38,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 38,
                height: 1.45,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 64,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1A1A1A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 24,
            letterSpacing: 4,
            color: Color(0xFF757575),
          ),
        ),
      ],
    );
  }
}
