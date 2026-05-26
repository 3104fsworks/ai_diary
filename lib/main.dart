import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/app_settings.dart';
import 'app/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final firebaseReady = await _initFirebase();
  final services = await ServiceLocator.bootstrap(
    settings: settings,
    firebaseReady: firebaseReady,
  );
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
