import 'dart:convert';

/// A single generated AI radio episode (weekly 3-min or monthly 5-min).
class RadioEpisode {
  final String id;        // e.g. "weekly_2026-05-25" / "monthly_2026-05-31"
  final DateTime generatedAt;
  final RadioEpisodeType type;
  final String script;
  final String audioFilePath;

  const RadioEpisode({
    required this.id,
    required this.generatedAt,
    required this.type,
    required this.script,
    required this.audioFilePath,
  });

  bool get isMonthly => type == RadioEpisodeType.monthly;

  /// Expected playback duration in seconds (3 min weekly / 5 min monthly).
  int get targetDurationSeconds => isMonthly ? 300 : 180;

  // ── Serialization ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'generatedAt': generatedAt.toIso8601String(),
        'type': type.name,
        'script': script,
        'audioFilePath': audioFilePath,
      };

  factory RadioEpisode.fromJson(Map<String, dynamic> j) => RadioEpisode(
        id: j['id'] as String,
        generatedAt: DateTime.parse(j['generatedAt'] as String),
        type: RadioEpisodeType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => RadioEpisodeType.weekly,
        ),
        script: j['script'] as String? ?? '',
        audioFilePath: j['audioFilePath'] as String? ?? '',
      );

  static List<RadioEpisode> listFromJsonString(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(RadioEpisode.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJsonString(List<RadioEpisode> episodes) =>
      jsonEncode(episodes.map((e) => e.toJson()).toList());
}

enum RadioEpisodeType { weekly, monthly }
