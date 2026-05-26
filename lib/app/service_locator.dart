import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/ai/routing_ai_diary_service.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/mock_auth_service.dart';
import '../core/auth/real_firebase_auth_service.dart';
import '../core/calendar/calendar_service.dart';
import '../core/calendar/mock_calendar_service.dart';
import '../core/calendar/real_google_calendar_service.dart';
import '../core/health/health_service.dart';
import '../core/health/mock_health_service.dart';
import '../core/health/real_health_service.dart';
import '../core/location/location_timeline_service.dart';
import '../core/purchase/mock_purchase_service.dart';
import '../core/purchase/purchase_service.dart';
import '../core/tasks/mock_tasks_service.dart';
import '../core/tasks/real_google_tasks_service.dart';
import '../core/tasks/tasks_service.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/survey_repository.dart';
import '../data/repositories/timeline_repository.dart';
import '../data/sources/local/local_diary_repository.dart';
import '../data/sources/local/local_survey_repository.dart';
import '../data/sources/local/local_timeline_repository.dart';
import '../data/sources/local/mock_diary_repository.dart';
import '../data/sources/memory/in_memory_survey_repository.dart';
import '../data/sources/memory/in_memory_timeline_repository.dart';
import 'app_settings.dart';

/// One-place service locator. Replaced later if we adopt a DI framework.
class ServiceLocator {
  ServiceLocator._({
    required this.diary,
    required this.timeline,
    required this.location,
    required this.ai,
    required this.health,
    required this.calendar,
    required this.tasks,
    required this.auth,
    required this.purchase,
    required this.survey,
  });

  final DiaryRepository diary;
  final TimelineRepository timeline;
  final LocationTimelineService location;
  final RoutingAiDiaryService ai;
  final HealthService health;
  final CalendarService calendar;
  final TasksService tasks;
  final AuthService auth;
  final PurchaseService purchase;
  final SurveyRepository survey;

  static Future<ServiceLocator> bootstrap({
    required AppSettings settings,
    bool firebaseReady = false,
  }) async {
    final DiaryRepository diary;
    final TimelineRepository timeline;
    final HealthService health;
    final SurveyRepository survey;
    if (kIsWeb) {
      diary = MockDiaryRepository();
      timeline = InMemoryTimelineRepository();
      health = MockHealthService();
      survey = InMemorySurveyRepository();
    } else {
      diary = await LocalDiaryRepository.open();
      timeline = await LocalTimelineRepository.open();
      health = RealHealthService();
      survey = await LocalSurveyRepository.open();
    }

    // Auth: real Firebase when initialized successfully, otherwise mocked
    // so Web previews and pre-Firebase development still work end-to-end.
    final AuthService auth =
        firebaseReady ? RealFirebaseAuthService() : MockAuthService();

    // Calendar / Tasks: hit real Google APIs whenever Firebase is up. The
    // Real services themselves return [] when the user has not granted the
    // required scope yet — the settings toggle is what triggers the scope
    // request.
    final CalendarService calendar = firebaseReady
        ? RealGoogleCalendarService(auth: auth)
        : MockCalendarService();
    final TasksService tasks = firebaseReady
        ? RealGoogleTasksService(auth: auth)
        : MockTasksService();

    // Purchase: mocked until RevenueCat is wired up. Real implementation
    // will use the purchases_flutter package + product configuration.
    final PurchaseService purchase = MockPurchaseService();

    final location = LocationTimelineService(repository: timeline);
    final services = ServiceLocator._(
      diary: diary,
      timeline: timeline,
      location: location,
      ai: RoutingAiDiaryService(settings: settings),
      health: health,
      calendar: calendar,
      tasks: tasks,
      auth: auth,
      purchase: purchase,
      survey: survey,
    );

    if (!kIsWeb && settings.locationEnabled) {
      await location.start();
    }

    return services;
  }
}

class Services extends InheritedWidget {
  final ServiceLocator locator;
  const Services({super.key, required this.locator, required super.child});

  static ServiceLocator of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<Services>();
    assert(s != null, 'Services missing in widget tree');
    return s!.locator;
  }

  @override
  bool updateShouldNotify(Services old) => old.locator != locator;
}
