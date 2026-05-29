/// Voice archetype for the AI radio narration.
///
/// 4 types × 2 genders = 8 distinct configurations.
/// [standard] is free; the rest require premium.
enum RadioVoiceType {
  standard,  // Default — neutral, polished
  healing,   // Empathetic, elegant, older presence  「癒し型」
  energetic, // Upbeat, encouraging, cheerful younger 「元気型」
  dj,        // Cool radio-DJ, objective, peer-like   「DJ型」
}

enum RadioVoiceGender { female, male }

extension RadioVoiceTypeLabel on RadioVoiceType {
  String get labelJa => switch (this) {
        RadioVoiceType.standard => 'デフォルト',
        RadioVoiceType.healing => '癒し・共感型',
        RadioVoiceType.energetic => '元気・応援型',
        RadioVoiceType.dj => 'ラジオDJ型',
      };

  String get descJa => switch (this) {
        RadioVoiceType.standard => '落ち着いた知的な語り口',
        RadioVoiceType.healing =>
          '出来事に寄り添い、共感してくれる品のある語り',
        RadioVoiceType.energetic =>
          '明るく元気に背中を押してくれる応援スタイル',
        RadioVoiceType.dj =>
          '客観的でクールなDJ視点。ネガもさらっと流してくれる',
      };

  bool get isPremium => this != RadioVoiceType.standard;

  String get storageKey => name;

  static RadioVoiceType fromStorage(String? key) {
    return RadioVoiceType.values.firstWhere(
      (v) => v.storageKey == key,
      orElse: () => RadioVoiceType.standard,
    );
  }
}

extension RadioVoiceGenderLabel on RadioVoiceGender {
  String get labelJa =>
      this == RadioVoiceGender.female ? '女性' : '男性';

  String get storageKey => name;

  static RadioVoiceGender fromStorage(String? key) {
    return key == 'male' ? RadioVoiceGender.male : RadioVoiceGender.female;
  }
}
