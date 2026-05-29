import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/service_locator.dart';
import 'core/notifications/diary_reminder_service.dart';
import 'core/notifications/radio_notification_service.dart';
import 'core/notifications/time_capsule_service.dart';
import 'core/purchase/real_revenue_cat_purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final firebaseReady = await _initFirebase();
  final services = await ServiceLocator.bootstrap(
    settings: settings,
    firebaseReady: firebaseReady,
  );
  await TimeCapsuleService.instance.init();    // also inits timezone data
  await RadioNotificationService.instance.init();
  await DiaryReminderService.instance.init();
  await RadioNotificationService.instance.scheduleAll(
    enabled: settings.radioNotificationsEnabled,
  );
  await DiaryReminderService.instance.scheduleDaily(
    hour: settings.diaryReminderHour,
    enabled: settings.diaryReminderEnabled,
  );

  // ── RevenueCat entitlement sync ─────────────────────────────────────────
  // Reads from the SDK's disk cache — safe to call offline on every startup.
  // Only runs on Android (Web uses MockPurchaseService).
  if (!kIsWeb && services.purchase is RealRevenueCatPurchaseService) {
    final purchaseSvc = services.purchase as RealRevenueCatPurchaseService;
    try {
      final active = await purchaseSvc.checkEntitlement();
      // Sync the cached premium flag both ways: grant if active, revoke if lapsed.
      // Exception: lifetimeFree / invite-code grants are independent keys and
      // are NOT touched by setPremium().
      await settings.setPremium(active);

      // Listen for real-time changes while the app is running
      // (e.g. subscription renewal, cancellation, billing retry).
      await purchaseSvc.listenToEntitlementChanges((isActive) async {
        await settings.setPremium(isActive);
      });
    } catch (e) {
      // SDK not configured yet (Play Console not set up) — leave cached state.
      debugPrint('[IAP] Entitlement sync skipped: $e');
    }
  }

  runApp(AiDiaryApp(settings: settings, services: services));
}

/// Attempts to bring up Firebase. Returns false on Web (we don't ship
/// Firebase web configuration), or when the platform config file
/// (google-services.json / GoogleService-Info.plist) is missing.
/// The app stays usable in this state via the Mock auth implementation.
Future<bool> _initFirebase() async {
  if (kIsWeb) return false;
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('Firebase init failed, falling back to MockAuthService: $e');
    return false;
  }
}
