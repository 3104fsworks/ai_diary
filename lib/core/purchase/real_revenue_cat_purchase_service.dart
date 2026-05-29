import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'product_info.dart';
import 'purchase_service.dart';

/// RevenueCat-backed implementation of [PurchaseService].
///
/// The public API key (goog_...) is safe to ship in the binary — it is not a
/// secret. RevenueCat uses it only to identify the app, not to authorize
/// server-side actions.
///
/// Product IDs and the 'premium' entitlement must be configured in the
/// RevenueCat dashboard AND linked to Google Play products before they
/// appear in offerings.
class RealRevenueCatPurchaseService implements PurchaseService {
  // Public Android client API key from the RevenueCat dashboard.
  // Dashboard: https://app.revenuecat.com → Project → API Keys → Android
  static const _androidApiKey = 'goog_SdOhXOfTWeGKAUGNiJxHqFYnKKu';

  /// RevenueCat entitlement identifier. Must match the dashboard exactly.
  static const _entitlementId = 'premium';

  bool _configured = false;

  // ── SDK lifecycle ────────────────────────────────────────────────────────

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    await Purchases.configure(PurchasesConfiguration(_androidApiKey));
    _configured = true;
  }

  /// Registers a callback that fires every time RevenueCat's CustomerInfo
  /// changes (subscription renewal, cancellation, etc.).
  ///
  /// Call once from [main] after [checkEntitlement] to keep
  /// [AppSettings.isPremium] in sync while the app is running.
  Future<void> listenToEntitlementChanges(
    void Function(bool isActive) onChanged,
  ) async {
    await _ensureConfigured();
    Purchases.addCustomerInfoUpdateListener((CustomerInfo info) {
      final active = info.entitlements.active.containsKey(_entitlementId);
      onChanged(active);
    });
  }

  // ── PurchaseService ──────────────────────────────────────────────────────

  @override
  bool get isSupported => true;

  @override
  Future<bool> checkEntitlement() async {
    await _ensureConfigured();
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (e) {
      // SDK failed (no network AND no cached data). Keep existing cached state.
      debugPrint('[RevenueCat] checkEntitlement error: $e');
      return false;
    }
  }

  @override
  Future<List<ProductInfo>> getProducts() async {
    await _ensureConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return [];
      return current.availablePackages.map((p) {
        return ProductInfo(
          id: p.storeProduct.identifier,
          displayName: p.storeProduct.title,
          price: p.storeProduct.priceString,
          period: _periodFromPackage(p),
        );
      }).toList();
    } catch (e) {
      debugPrint('[RevenueCat] getProducts error: $e');
      return [];
    }
  }

  @override
  Future<PurchaseResult> purchase(String productId) async {
    await _ensureConfigured();
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) {
        return const PurchaseResult(
          status: PurchaseStatus.error,
          message: 'No offerings available. Check RevenueCat dashboard.',
        );
      }

      // Find the package with matching product ID, fall back to first.
      final package = current.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
        orElse: () => current.availablePackages.first,
      );

      final customerInfo = await Purchases.purchasePackage(package);
      final active = customerInfo.entitlements.active[_entitlementId];
      if (active != null) {
        return const PurchaseResult(status: PurchaseStatus.success);
      }
      return const PurchaseResult(
        status: PurchaseStatus.error,
        message: 'Entitlement not granted after purchase.',
      );
    } on PurchasesError catch (e) {
      // purchases_flutter throws PurchasesError (not PurchasesErrorCode directly).
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseResult(status: PurchaseStatus.cancelled);
      }
      debugPrint('[RevenueCat] purchase error: ${e.code} — ${e.message}');
      return PurchaseResult(
        status: PurchaseStatus.error,
        message: e.message,
      );
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, message: '$e');
    }
  }

  @override
  Future<PurchaseResult> restore() async {
    await _ensureConfigured();
    try {
      final customerInfo = await Purchases.restorePurchases();
      final active = customerInfo.entitlements.active[_entitlementId];
      if (active != null) {
        return const PurchaseResult(status: PurchaseStatus.success);
      }
      return const PurchaseResult(
        status: PurchaseStatus.error,
        message: 'No active subscription found.',
      );
    } on PurchasesError catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, message: e.message);
    } catch (e) {
      return PurchaseResult(status: PurchaseStatus.error, message: '$e');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _periodFromPackage(Package p) {
    return switch (p.packageType) {
      PackageType.monthly => 'monthly',
      PackageType.annual => 'yearly',
      PackageType.lifetime => 'lifetime',
      PackageType.weekly => 'weekly',
      _ => 'monthly',
    };
  }
}
