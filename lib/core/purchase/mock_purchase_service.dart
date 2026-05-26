import 'product_info.dart';
import 'purchase_service.dart';

/// Returns the product catalog the plan screen needs and pretends every
/// purchase succeeds. Wire RevenueCat in later — the UI never has to change.
class MockPurchaseService implements PurchaseService {
  @override
  bool get isSupported => false;

  @override
  Future<List<ProductInfo>> getProducts() async {
    return const [
      ProductInfo(
        id: 'ai_journal_voice_monthly',
        displayName: '音声入力プラン',
        price: '¥300',
        period: 'monthly',
      ),
      ProductInfo(
        id: 'ai_journal_voice_photo_monthly',
        displayName: '音声＋写真プラン',
        price: '¥500',
        period: 'monthly',
      ),
      ProductInfo(
        id: 'ai_journal_full_monthly',
        displayName: 'フル機能プラン',
        price: '¥1,000',
        period: 'monthly',
      ),
    ];
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const PurchaseResult(status: PurchaseStatus.success);
  }

  @override
  Future<PurchaseResult> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const PurchaseResult(status: PurchaseStatus.success);
  }
}
