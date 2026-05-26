import 'goal_item.dart';

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
  final String? aiFeedback;
  final List<String> photoPaths;
  final List<GoalItem> goals;
  final WeatherInfo? weather;
  final ActivityInfo? activity;
  final List<ScheduleItem> schedule;
  final List<String> doneTasks;
  final List<TimelineStop> timeline;

  const DiaryEntry({
    required this.id,
    required this.date,
    this.aiTitle,
    this.userMemo = '',
    this.rawVoiceMemo = '',
    this.aiJournal,
    this.aiFeedback,
    this.photoPaths = const [],
    this.goals = const [],
    this.weather,
    this.activity,
    this.schedule = const [],
    this.doneTasks = const [],
    this.timeline = const [],
  });

  DiaryEntry copyWith({
    String? aiTitle,
    String? userMemo,
    String? rawVoiceMemo,
    String? aiJournal,
    String? aiFeedback,
    List<String>? photoPaths,
    List<GoalItem>? goals,
    WeatherInfo? weather,
    ActivityInfo? activity,
    List<ScheduleItem>? schedule,
    List<String>? doneTasks,
    List<TimelineStop>? timeline,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      aiTitle: aiTitle ?? this.aiTitle,
      userMemo: userMemo ?? this.userMemo,
      rawVoiceMemo: rawVoiceMemo ?? this.rawVoiceMemo,
      aiJournal: aiJournal ?? this.aiJournal,
      aiFeedback: aiFeedback ?? this.aiFeedback,
      photoPaths: photoPaths ?? this.photoPaths,
      goals: goals ?? this.goals,
      weather: weather ?? this.weather,
      activity: activity ?? this.activity,
      schedule: schedule ?? this.schedule,
      doneTasks: doneTasks ?? this.doneTasks,
      timeline: timeline ?? this.timeline,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'aiTitle': aiTitle,
        'userMemo': userMemo,
        'rawVoiceMemo': rawVoiceMemo,
        'aiJournal': aiJournal,
        'aiFeedback': aiFeedback,
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
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> j) {
    return DiaryEntry(
      id: j['id'] as String,
      date: DateTime.parse(j['date'] as String),
      aiTitle: j['aiTitle'] as String?,
      userMemo: (j['userMemo'] as String?) ?? '',
      rawVoiceMemo: (j['rawVoiceMemo'] as String?) ?? '',
      aiJournal: j['aiJournal'] as String?,
      aiFeedback: j['aiFeedback'] as String?,
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
