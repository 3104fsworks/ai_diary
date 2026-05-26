import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/diary_entry.dart';

/// Converts a [DiaryEntry] to standard Markdown that Obsidian and Notion
/// can ingest as-is, then writes it to a temp file and opens the OS share sheet.
class DiaryMarkdownExporter {
  DiaryMarkdownExporter._();

  static String render(DiaryEntry e) {
    final buf = StringBuffer();
    final ymd = e.date.toIso8601String().substring(0, 10);

    // Frontmatter — Obsidian / Notion friendly
    buf.writeln('---');
    buf.writeln('date: $ymd');
    if (e.aiTitle != null) buf.writeln('title: "${_escape(e.aiTitle!)}"');
    if (e.weather != null) {
      buf.writeln('weather: ${e.weather!.kind.name}');
      buf.writeln('temperature_c: ${e.weather!.tempC.toStringAsFixed(0)}');
      buf.writeln('place: "${_escape(e.weather!.place)}"');
    }
    buf.writeln('tags: [ai-diary]');
    buf.writeln('---');
    buf.writeln();

    buf.writeln('# ${e.aiTitle ?? ymd}');
    buf.writeln();
    buf.writeln('_$ymd${e.weather != null ? ' · ${_weatherLabel(e.weather!.kind)}' : ''}_');
    buf.writeln();

    if (e.goals.isNotEmpty) {
      buf.writeln('## Goals');
      for (final g in e.goals) {
        buf.writeln('- ${g.checked ? '[x]' : '[ ]'} ${g.labelKey}');
      }
      buf.writeln();
    }

    if (e.aiJournal != null && e.aiJournal!.isNotEmpty) {
      buf.writeln('## Journal');
      buf.writeln(e.aiJournal);
      buf.writeln();
    }

    if (e.activity != null) {
      buf.writeln('## Stats');
      buf.writeln('- Steps: ${e.activity!.steps}');
      buf.writeln(
        '- Sleep: ${e.activity!.sleepHours.toStringAsFixed(1)} h',
      );
      buf.writeln();
    }

    if (e.schedule.isNotEmpty) {
      buf.writeln('## Schedule');
      for (final s in e.schedule) {
        buf.writeln('- ${s.time != null ? '${s.time} — ' : ''}${s.title}');
      }
      buf.writeln();
    }

    if (e.doneTasks.isNotEmpty) {
      buf.writeln('## Done');
      for (final t in e.doneTasks) {
        buf.writeln('- $t');
      }
      buf.writeln();
    }

    if (e.timeline.isNotEmpty) {
      buf.writeln('## Timeline');
      for (final t in e.timeline) {
        buf.writeln('- ${t.time} · ${t.place}');
      }
      buf.writeln();
    }

    if (e.userMemo.isNotEmpty) {
      buf.writeln('## Memo');
      buf.writeln(e.userMemo);
      buf.writeln();
    }

    // The user's raw voice — kept verbatim, never AI-rewritten.
    if (e.rawVoiceMemo.isNotEmpty) {
      buf.writeln('## 今日のつぶやき');
      for (final line in e.rawVoiceMemo.split('\n')) {
        buf.writeln('> $line');
      }
      buf.writeln();
    }

    if (e.aiFeedback != null && e.aiFeedback!.isNotEmpty) {
      buf.writeln('---');
      buf.writeln();
      buf.writeln('> ${e.aiFeedback}');
      buf.writeln();
    }

    return buf.toString();
  }

  /// Writes the diary to a temp .md file and opens the OS share sheet.
  static Future<void> share(DiaryEntry e) async {
    final tmp = await getTemporaryDirectory();
    final ymd = e.date.toIso8601String().substring(0, 10);
    final f = File('${tmp.path}${Platform.pathSeparator}ai-diary-$ymd.md');
    await f.writeAsString(render(e));
    await Share.shareXFiles([XFile(f.path)]);
  }

  static String _escape(String s) => s.replaceAll('"', r'\"');

  static String _weatherLabel(WeatherKind k) => switch (k) {
        WeatherKind.sunny => 'Sunny',
        WeatherKind.cloudy => 'Cloudy',
        WeatherKind.rainy => 'Rainy',
        WeatherKind.snowy => 'Snowy',
      };
}
