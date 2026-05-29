import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/diary_entry.dart';
import '../../data/models/voice_metadata.dart';

/// Converts a [DiaryEntry] to the AI Diary dual-language Markdown format.
///
/// Output contains:
///   - YAML frontmatter (date, metrics, tags)
///   - Daily Goals (checkbox list)
///   - AI Journal JP (full first-person diary)
///   - AI Journal EN (3-4 sentence summary for AI Radio token efficiency)
///   - AI Feedback (bilingual)
///   - User Records (raw voice transcript, text notes, photos)
///   - Life Log (calendar, tasks)
///   - AI Radio Index (collapsible EN-only compact block)
///
/// Obsidian, Notion, and Bear can all ingest this format as-is.
class DiaryMarkdownExporter {
  DiaryMarkdownExporter._();

  // ── Public API ────────────────────────────────────────────────────────────

  static String render(DiaryEntry e) {
    final buf = StringBuffer();
    final ymd = _ymd(e.date);
    final dow = _dow(e.date);

    // ── YAML Frontmatter ───────────────────────────────────────────────────
    buf.writeln('---');
    buf.writeln('date: $ymd');
    buf.writeln('day_of_week: $dow');
    if (e.weather != null) {
      buf.writeln('weather: ${_weatherEmoji(e.weather!.kind)}');
      buf.writeln('location: [${_locationEmoji(e.weather!.place)}]');
    } else {
      buf.writeln('weather: —');
      buf.writeln('location: []');
    }
    if (e.activity != null) {
      buf.writeln('steps: ${e.activity!.steps}');
      buf.writeln('sleep_duration: ${_sleepDuration(e.activity!.sleepHours)}');
      buf.writeln('sleep_quality: ${_sleepQuality(e.activity!.sleepHours)}');
    } else {
      buf.writeln('steps: 0');
      buf.writeln('sleep_duration: —');
      buf.writeln('sleep_quality: —');
    }
    final energy = _energyLevel(e.voiceMetadata);
    final stress = _stressLevel(e.voiceMetadata);
    buf.writeln('stress_level: $stress');
    buf.writeln('energy_level: $energy');
    buf.writeln('tags:');
    buf.writeln('  - daily-journal');
    buf.writeln('  - ai-generated');
    buf.writeln('---');
    buf.writeln();

    // ── Page title ──────────────────────────────────────────────────────────
    buf.writeln('# ✍️ $ymd $dow Daily Log');
    buf.writeln();

    // ── Daily Goals ────────────────────────────────────────────────────────
    if (e.goals.isNotEmpty) {
      buf.writeln('## 🎯 Daily Goals / 本日の目標');
      for (final g in e.goals) {
        buf.writeln('- ${g.checked ? '[x]' : '[ ]'} ${g.labelKey}');
      }
      buf.writeln();
      buf.writeln('---');
      buf.writeln();
    }

    // ── AI Journal & Feedback ──────────────────────────────────────────────
    buf.writeln('## 🤖 AI Journal & Feedback / AI日記とフィードバック');
    buf.writeln();

    if (e.aiJournal != null && e.aiJournal!.isNotEmpty) {
      buf.writeln('### 📖 Journal (Japanese) / 日記本文（日本語）');
      buf.writeln(e.aiJournal);
      buf.writeln();
    }

    if (e.aiJournalEn != null && e.aiJournalEn!.isNotEmpty) {
      buf.writeln('### 📖 Journal (English Summary) / 日記の英語要約');
      buf.writeln('*${e.aiJournalEn}*');
      buf.writeln();
    }

    final hasFeedbackJp = e.aiFeedback != null && e.aiFeedback!.isNotEmpty;
    final hasFeedbackEn = e.aiFeedbackEn != null && e.aiFeedbackEn!.isNotEmpty;
    if (hasFeedbackJp || hasFeedbackEn) {
      buf.writeln('> 💡 **AI Feedback / AIからのコメント**');
      if (hasFeedbackJp) buf.writeln('> **[JP]** ${e.aiFeedback}');
      if (hasFeedbackEn) buf.writeln('> **[EN]** ${e.aiFeedbackEn}');
      buf.writeln();
    }

    buf.writeln('---');
    buf.writeln();

    // ── User Records ───────────────────────────────────────────────────────
    buf.writeln('## 👤 User Records / ユーザー記録（手動・音声）');
    buf.writeln();

    if (e.rawVoiceMemo.isNotEmpty) {
      buf.writeln('### 🎙️ Raw Voice Transcript / 生の声のつぶやき');
      for (final line in e.rawVoiceMemo.split('\n')) {
        buf.writeln('> $line');
      }
      buf.writeln();
    }

    buf.writeln('### 📝 Text Notes / 今日の手入力メモ');
    if (e.userMemo.isNotEmpty) {
      buf.writeln(e.userMemo);
    }
    // Placeholder so the app can inject notes later
    buf.writeln();

    if (e.photoPaths.isNotEmpty) {
      buf.writeln('### 📷 Today\'s Photos / 今日の写真');
      final dateCompact = ymd.replaceAll('-', '');
      for (var i = 0; i < e.photoPaths.length; i++) {
        final idx = (i + 1).toString().padLeft(2, '0');
        final path = e.photoPaths[i];
        buf.writeln('![今日の写真${i + 1}]($path)');
        // Photo AI captions are populated by the photo-import feature (future).
        buf.writeln('*🤖 AI Photo Caption: (app_assets/${dateCompact}_$idx.webp — caption pending)*');
        buf.writeln();
      }
    }

    buf.writeln('---');
    buf.writeln();

    // ── Life Log ───────────────────────────────────────────────────────────
    buf.writeln('## 📱 Life Log / ライフログ（外部連携データ）');
    buf.writeln();
    buf.writeln('### 📅 Calendar & Tasks / 今日の予定 & タスク');
    buf.writeln('**Google Calendar:**');
    if (e.schedule.isEmpty) {
      buf.writeln('- カレンダー未記入・のんびりした1日 / No events');
    } else {
      for (final s in e.schedule) {
        final time = s.time != null ? '${s.time} ' : '';
        buf.writeln('- $time${s.title}');
      }
    }
    buf.writeln();

    buf.writeln('**Google ToDo (Completed):**');
    if (e.doneTasks.isEmpty) {
      buf.writeln('- （完了タスクなし / No completed tasks）');
    } else {
      for (final t in e.doneTasks) {
        buf.writeln('- [x] $t');
      }
    }
    buf.writeln();

    buf.writeln('---');
    buf.writeln();

    // ── AI Radio Index ─────────────────────────────────────────────────────
    buf.writeln('## 🤖 AI Radio Index / ラジオ用インデックス（トークン節約用）');
    buf.writeln('> [!NOTE] AI Radio Summary (For internal processing)');
    buf.writeln('> <details><summary>Click to expand / クリックで展開</summary>');
    buf.writeln('>');
    buf.writeln('> - **Date:** $ymd $dow');
    if (e.activity != null) {
      buf.writeln(
        '> - **Metrics:** Steps: ${e.activity!.steps}'
        ' / Stress: $stress / Energy: $energy'
        ' / Sleep: ${_sleepDuration(e.activity!.sleepHours)}'
        ' (${_sleepQuality(e.activity!.sleepHours)})',
      );
    }
    if (e.aiRadioIndex != null && e.aiRadioIndex!.isNotEmpty) {
      for (final line in e.aiRadioIndex!.split('\n')) {
        buf.writeln('> $line');
      }
    } else {
      // Fallback: build a basic index from available data
      final summary = (e.aiJournalEn ?? e.aiJournal ?? '').trim();
      final snippet = summary.length > 120
          ? '${summary.substring(0, 120)}…'
          : summary;
      buf.writeln('> - **Core Action:** $snippet');
      buf.writeln('> - **AI Sentiment:** —');
    }
    buf.writeln('> </details>');
    buf.writeln();

    return buf.toString();
  }

  /// Writes the diary to a temp .md file and opens the OS share sheet.
  static Future<void> share(DiaryEntry e) async {
    final tmp = await getTemporaryDirectory();
    final f = File('${tmp.path}${Platform.pathSeparator}ai-diary-${_ymd(e.date)}.md');
    await f.writeAsString(render(e));
    await Share.shareXFiles([XFile(f.path)]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Returns 3-char English weekday abbreviation.
  /// DateTime.weekday: 1 = Monday … 7 = Sunday.
  static String _dow(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[d.weekday - 1];
  }

  static String _weatherEmoji(WeatherKind k) => switch (k) {
        WeatherKind.sunny => '☀️ Clear',
        WeatherKind.cloudy => '☁️ Cloudy',
        WeatherKind.rainy => '🌧️ Rainy',
        WeatherKind.snowy => '🌨️ Snowy',
      };

  static String _locationEmoji(String place) => '📍 $place';

  /// Formats decimal hours as HH:MM  e.g. 6.75 → "06:45"
  static String _sleepDuration(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Derives sleep quality from hours slept.
  static String _sleepQuality(double hours) {
    if (hours >= 7.0) return 'Good';
    if (hours >= 5.0) return 'Fair';
    return 'Poor';
  }

  /// Energy level 0-100 derived from [VoiceMetadata.emotionTemperature].
  static int _energyLevel(VoiceMetadata? voiceMetadata) {
    if (voiceMetadata == null) return 50;
    return (voiceMetadata.emotionTemperature.clamp(0.0, 1.0) * 100).round();
  }

  /// Stress level 0-100 (inverse of energy, capped at 70 to avoid
  /// over-inferring from amplitude alone).
  static int _stressLevel(VoiceMetadata? voiceMetadata) {
    final energy = _energyLevel(voiceMetadata);
    return ((100 - energy) * 0.7).round();
  }
}
