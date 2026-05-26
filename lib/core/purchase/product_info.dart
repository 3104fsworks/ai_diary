/// A product the user can purchase. Mapped 1:1 to the IDs configured in
/// App Store Connect / Google Play Console (and surfaced via RevenueCat).
class ProductInfo {
  /// Stable product identifier (e.g. `ai_journal_voice_monthly`).
  final String id;

  /// User-facing display name ("音声入力プラン").
  final String displayName;

  /// Pre-formatted price string (RevenueCat returns this localized).
  final String price;

  /// Period: `monthly` / `yearly` / `lifetime`.
  final String period;

  const ProductInfo({
    required this.id,
    required this.displayName,
    required this.price,
    required this.period,
  });
}

/// Outcome of a purchase attempt.
enum PurchaseStatus { success, cancelled, error, pending }

class PurchaseResult {
  final PurchaseStatus status;
  final String? message;
  const PurchaseResult({required this.status, this.message});
}
