/// Tone & manner used by the AI when generating the diary and feedback.
enum AiPersonality {
  /// Polite, intellectual, restrained. Default.
  standard,

  /// Mirrors the user's own voice (endings, tension, vocabulary).
  mirroring,

  /// Friendly best-friend tone — soft, encouraging, slightly more kana.
  friendly;

  String get storageKey => switch (this) {
        AiPersonality.standard => 'standard',
        AiPersonality.mirroring => 'mirroring',
        AiPersonality.friendly => 'friendly',
      };

  static AiPersonality fromStorage(String? key) {
    return switch (key) {
      'mirroring' => AiPersonality.mirroring,
      'friendly' => AiPersonality.friendly,
      _ => AiPersonality.standard,
    };
  }
}
