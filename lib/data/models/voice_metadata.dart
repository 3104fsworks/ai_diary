/// Voice characteristics captured during a 2-minute recording session.
///
/// Used for two purposes:
///  1. Emotional temperature → weekly AI radio selects ambient BGM
///     (energetic week = bright ambient, tired week = quiet lo-fi / fireplace)
///  2. Time-series tracking of user well-being over days/weeks
class VoiceMetadata {
  /// Mean normalised amplitude over all samples (0.0 = silent, 1.0 = peak).
  final double averageAmplitude;

  /// Fraction of samples that fell below the silence threshold.
  /// 0.0 = talking the whole time, 1.0 = total silence.
  final double silenceRatio;

  /// Actual recording duration in seconds (≤ 120 for the 2-minute limit).
  final int totalDurationSeconds;

  /// Derived emotional temperature: 0.0 = calm / tired, 1.0 = energetic.
  /// Higher amplitude + lower silence → higher temperature.
  /// Used by the weekly AI radio to pick the BGM mood.
  final double emotionTemperature;

  const VoiceMetadata({
    required this.averageAmplitude,
    required this.silenceRatio,
    required this.totalDurationSeconds,
    required this.emotionTemperature,
  });

  /// Computes a [VoiceMetadata] from a list of normalised amplitude samples
  /// (each sample is 0.0–1.0, sampled every 500 ms during recording).
  ///
  /// [silenceThreshold] defaults to 0.15 — samples below this are counted as
  /// silence. Adjust if ambient noise in target environments is high.
  factory VoiceMetadata.compute({
    required List<double> amplitudeSamples,
    required int totalDurationSeconds,
    double silenceThreshold = 0.15,
  }) {
    if (amplitudeSamples.isEmpty) {
      return const VoiceMetadata(
        averageAmplitude: 0,
        silenceRatio: 1,
        totalDurationSeconds: 0,
        emotionTemperature: 0,
      );
    }

    final avg =
        amplitudeSamples.reduce((a, b) => a + b) / amplitudeSamples.length;
    final silentCount =
        amplitudeSamples.where((a) => a < silenceThreshold).length;
    final silenceRatio = silentCount / amplitudeSamples.length;

    // Weighted: 70% amplitude energy + 30% speaking continuity.
    final temperature =
        ((avg * 0.7) + ((1.0 - silenceRatio) * 0.3)).clamp(0.0, 1.0);

    return VoiceMetadata(
      averageAmplitude: avg,
      silenceRatio: silenceRatio,
      totalDurationSeconds: totalDurationSeconds,
      emotionTemperature: temperature,
    );
  }

  Map<String, dynamic> toJson() => {
        'averageAmplitude': averageAmplitude,
        'silenceRatio': silenceRatio,
        'totalDurationSeconds': totalDurationSeconds,
        'emotionTemperature': emotionTemperature,
      };

  factory VoiceMetadata.fromJson(Map<String, dynamic> j) => VoiceMetadata(
        averageAmplitude: (j['averageAmplitude'] as num).toDouble(),
        silenceRatio: (j['silenceRatio'] as num).toDouble(),
        totalDurationSeconds: (j['totalDurationSeconds'] as num).toInt(),
        emotionTemperature: (j['emotionTemperature'] as num).toDouble(),
      );
}
