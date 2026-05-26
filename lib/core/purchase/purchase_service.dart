import 'product_info.dart';

/// In-app purchase / subscription bridge.
/// Implementations:
///   • [MockPurchaseService] for development
///   • RealRevenueCatService (to be added once RevenueCat is set up)
abstract class PurchaseService {
  /// Whether the platform supports real purchases (false on Web / desktop).
  bool get isSupported;

  /// Catalog of available products.
  Future<List<ProductInfo>> getProducts();

  /// Initiates the platform purchase flow for [productId].
  Future<PurchaseResult> purchase(String productId);

  /// Restores entitlements (e.g. user reinstalled the app).
  Future<PurchaseResult> restore();
}
