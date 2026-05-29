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

  /// Checks whether the user currently holds an active premium entitlement.
  ///
  /// Reads from the SDK's local cache when offline — safe to call on startup.
  /// Returns false when not subscribed or when the platform doesn't support
  /// real purchases (e.g. Web).
  Future<bool> checkEntitlement();
}
