/// Captured answers from the onboarding survey.
///
/// We keep the question order stable so a later Firestore upload can
/// be diffed/versioned. Free-text fields are stored verbatim.
class SurveyResponse {
  /// Local capture time, UTC ISO 8601.
  final DateTime capturedAt;
  /// Anonymous user id at the time of capture (empty if signed out).
  final String userId;
  /// Free-text country if user selected "その他".
  /// Currently we only capture the chosen option labels; expand later.
  final Map<int, List<String>> choices;
  final String? painText;
  final String? wishText;

  const SurveyResponse({
    required this.capturedAt,
    required this.userId,
    required this.choices,
    this.painText,
    this.wishText,
  });

  Map<String, dynamic> toJson() => {
        'capturedAt': capturedAt.toIso8601String(),
        'userId': userId,
        'choices': {
          for (final e in choices.entries) e.key.toString(): e.value,
        },
        if (painText != null) 'painText': painText,
        if (wishText != null) 'wishText': wishText,
      };

  factory SurveyResponse.fromJson(Map<String, dynamic> j) {
    final choicesRaw = (j['choices'] as Map?) ?? const {};
    final choices = <int, List<String>>{};
    choicesRaw.forEach((k, v) {
      final key = int.tryParse(k.toString());
      if (key == null) return;
      choices[key] =
          (v as List).map((e) => e.toString()).toList(growable: false);
    });
    return SurveyResponse(
      capturedAt: DateTime.parse(j['capturedAt'] as String),
      userId: (j['userId'] as String?) ?? '',
      choices: choices,
      painText: j['painText'] as String?,
      wishText: j['wishText'] as String?,
    );
  }
}
