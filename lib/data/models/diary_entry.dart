import 'goal_item.dart';
import 'voice_metadata.dart';

class DiaryEntry {
  final String id;
  final DateTime date;
  final String? aiTitle;
  final String userMemo;

  /// Raw voice transcript, kept verbatim, NEVER rewritten by AI.
  /// This is the user's own words — preserved so they never feel
  /// their authentic voice was lost.
  final String rawVoiceMemo;

  final String? aiJournal;

  /// 3-4 sentence English summary of [aiJournal], generated simultaneously.
  /// Used by AI Radio to reduce token consumption during long-term lookback.
  final String? aiJournalEn;

  final String? aiFeedback;

  /// English translation of [aiFeedback].
  final String? aiFeedbackEn;

  /// Ultra-compact English bullet block for the AI Radio Index.
  /// Contains Core Action (2 sentences) and AI Sentiment (2 keywords).
  final String? aiRadioIndex;
  final List<String> photoPaths;
  final List<GoalItem> goals;
  final WeatherInfo? weather;
  final ActivityInfo? activity;
  final List<ScheduleItem> schedule;
  final List<String> doneTasks;
  final List<TimelineStop> timeline;

  /// Local file path to the raw audio recording (.m4a).
  ///
  /// Null when voice input was not used, or the audio file has been cleaned up
  /// (free users: files older than 7 days are deleted by AudioCleanupService).
  /// Premium users retain audio indefinitely. Check file existence at runtime
  /// before showing a playback UI — the path may reference a deleted file.
  final String? audioFilePath;

  /// Actual duration of the voice recording in seconds (≤ 120).
  final int? audioDurationSeconds;

  /// If non-null, a local push notification should fire at this datetime
  /// to surface this entry as a "time capsule" message from the past self.
  ///
  /// Set when the AI (or the user) designates an entry as a time-capsule,
  /// e.g. when the transcript contains "○ヶ月後の自分へ" phrasing.
  final DateTime? capsuleDeliveryDate;

  /// Non-language voice characteristics derived from the audio recording.
  ///
  /// Used by the weekly AI radio to choose ambient BGM mood, and for
  /// long-term well-being analytics (emotionTemperature trend over weeks).
  final VoiceMetadata? voiceMetadata;

  const DiaryEntry({
    required this.id,
    required this.date,
    this.aiTitle,
    this.userMemo = '',
    this.rawVoiceMemo = '',
    this.aiJournal,
    this.aiJournalEn,
    this.aiFeedback,
    this.aiFeedbackEn,
    this.aiRadioIndex,
    this.photoPaths = const [],
    this.goals = const [],
    this.weather,
    this.activity,
    this.schedule = const [],
    this.doneTasks = const [],
    this.timeline = const [],
    this.audioFilePath,
    this.audioDurationSeconds,
    this.capsuleDeliveryDate,
    this.voiceMetadata,
  });

  // ---------------------------------------------------------------------------
  // copyWith — uses Object? + sentinel to allow setting a field back to null.
  // For simple String?/int?/DateTime?/VoiceMetadata? fields we rely on the
  // caller: pass the actual null when they mean "clear this field".
  // ---------------------------------------------------------------------------
  DiaryEntry copyWith({
    String? aiTitle,
    String? userMemo,
    String? rawVoiceMemo,
    String? aiJournal,
    String? aiJournalEn,
    String? aiFeedback,
    String? aiFeedbackEn,
    String? aiRadioIndex,
    List<String>? photoPaths,
    List<GoalItem>? goals,
    WeatherInfo? weather,
    ActivityInfo? activity,
    List<ScheduleItem>? schedule,
    List<String>? doneTasks,
    List<TimelineStop>? timeline,
    // Nullable fields use Object? + sentinel so callers can explicitly clear
    // them (e.g. AudioCleanupService setting audioFilePath back to null).
    Object? audioFilePath = _keep,
    Object? audioDurationSeconds = _keep,
    Object? capsuleDeliveryDate = _keep,
    Object? voiceMetadata = _keep,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      aiTitle: aiTitle ?? this.aiTitle,
      userMemo: userMemo ?? this.userMemo,
      rawVoiceMemo: rawVoiceMemo ?? this.rawVoiceMemo,
      aiJournal: aiJournal ?? this.aiJournal,
      aiJournalEn: aiJournalEn ?? this.aiJournalEn,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      aiFeedbackEn: aiFeedbackEn ?? this.aiFeedbackEn,
      aiRadioIndex: aiRadioIndex ?? this.aiRadioIndex,
      photoPaths: photoPaths ?? this.photoPaths,
      goals: goals ?? this.goals,
      weather: weather ?? this.weather,
      activity: activity ?? this.activity,
      schedule: schedule ?? this.schedule,
      doneTasks: doneTasks ?? this.doneTasks,
      timeline: timeline ?? this.timeline,
      audioFilePath: identical(audioFilePath, _keep)
          ? this.audioFilePath
          : audioFilePath as String?,
      audioDurationSeconds: identical(audioDurationSeconds, _keep)
          ? this.audioDurationSeconds
          : audioDurationSeconds as int?,
      capsuleDeliveryDate: identical(capsuleDeliveryDate, _keep)
          ? this.capsuleDeliveryDate
          : capsuleDeliveryDate as DateTime?,
      voiceMetadata: identical(voiceMetadata, _keep)
          ? this.voiceMetadata
          : voiceMetadata as VoiceMetadata?,
    );
  }

  /// Sentinel: signals "don't change this field" in [copyWith].
  static const _keep = Object();

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'aiTitle': aiTitle,
        'userMemo': userMemo,
        'rawVoiceMemo': rawVoiceMemo,
        'aiJournal': aiJournal,
        'aiJournalEn': aiJournalEn,
        'aiFeedback': aiFeedback,
        'aiFeedbackEn': aiFeedbackEn,
        'aiRadioIndex': aiRadioIndex,
        'photoPaths': photoPaths,
        'goals': goals
            .map((g) => {
                  'id': g.id,
                  'labelKey': g.labelKey,
                  'checked': g.checked,
                })
            .toList(),
        'weather': weather == null
            ? null
            : {
                'kind': weather!.kind.name,
                'tempC': weather!.tempC,
                'place': weather!.place,
              },
        'activity': activity == null
            ? null
            : {
                'steps': activity!.steps,
                'sleepHours': activity!.sleepHours,
              },
        'schedule':
            schedule.map((s) => {'title': s.title, 'time': s.time}).toList(),
        'doneTasks': doneTasks,
        'timeline':
            timeline.map((t) => {'place': t.place, 'time': t.time}).toList(),
        'audioFilePath': audioFilePath,
        'audioDurationSeconds': audioDurationSeconds,
        'capsuleDeliveryDate': capsuleDeliveryDate?.toIso8601String(),
        'voiceMetadata': voiceMetadata?.toJson(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> j) {
    return DiaryEntry(
      id: j['id'] as String,
      date: DateTime.parse(j['date'] as String),
      aiTitle: j['aiTitle'] as String?,
      userMemo: (j['userMemo'] as String?) ?? '',
      rawVoiceMemo: (j['rawVoiceMemo'] as String?) ?? '',
      aiJournal: j['aiJournal'] as String?,
      aiJournalEn: j['aiJournalEn'] as String?,
      aiFeedback: j['aiFeedback'] as String?,
      aiFeedbackEn: j['aiFeedbackEn'] as String?,
      aiRadioIndex: j['aiRadioIndex'] as String?,
      photoPaths: ((j['photoPaths'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      goals: ((j['goals'] as List?) ?? const [])
          .map((e) => e as Map<String, dynamic>)
          .map((m) => GoalItem(
                id: m['id'] as String,
                labelKey: m['labelKey'] as String,
                checked: (m['checked'] as bool?) ?? false,
              ))
          .toList(),
      weather: j['weather'] == null
          ? null
          : WeatherInfo(
              kind: WeatherKind.values.firstWhere(
                (k) => k.name == (j['weather'] as Map)['kind'],
                orElse: () => WeatherKind.sunny,
              ),
              tempC: ((j['weather'] as Map)['tempC'] as num).toDouble(),
              place: (j['weather'] as Map)['place'] as String,
            ),
      activity: j['activity'] == null
          ? null
          : ActivityInfo(
              steps: (j['activity'] as Map)['steps'] as int,
              sleepHours:
                  ((j['activity'] as Map)['sleepHours'] as num).toDouble(),
            ),
      schedule: ((j['schedule'] as List?) ?? const [])
          .map((e) => e as Map<String, dynamic>)
          .map((m) => ScheduleItem(
                title: m['title'] as String,
                time: m['time'] as String?,
              ))
          .toList(),
      doneTasks: ((j['doneTasks'] as List?) ?? const [])
          .map((e) => e as String)
          .toList(),
      timeline: ((j['timeline'] as List?) ?? const [])
          .map((e) => e as Map<String, dynamic>)
          .map((m) => TimelineStop(
                place: m['place'] as String,
                time: m['time'] as String,
              ))
          .toList(),
      // New fields — all nullable with safe fallback for existing JSON files
      // that predate these fields (backward compatible).
      audioFilePath: j['audioFilePath'] as String?,
      audioDurationSeconds: j['audioDurationSeconds'] as int?,
      capsuleDeliveryDate: j['capsuleDeliveryDate'] == null
          ? null
          : DateTime.tryParse(j['capsuleDeliveryDate'] as String),
      voiceMetadata: j['voiceMetadata'] == null
          ? null
          : VoiceMetadata.fromJson(
              j['voiceMetadata'] as Map<String, dynamic>),
    );
  }
}

enum WeatherKind { sunny, cloudy, rainy, snowy }

class WeatherInfo {
  final WeatherKind kind;
  final double tempC;
  final String place;
  const WeatherInfo({
    required this.kind,
    required this.tempC,
    required this.place,
  });
}

class ActivityInfo {
  final int steps;
  final double sleepHours;
  const ActivityInfo({required this.steps, required this.sleepHours});
}

class ScheduleItem {
  final String title;
  final String? time;
  const ScheduleItem({required this.title, this.time});
}

class TimelineStop {
  final String place;
  final String time;
  const TimelineStop({required this.place, required this.time});
}
