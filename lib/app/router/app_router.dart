import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/diary/diary_edit_screen.dart';
import '../../features/history/history_detail_screen.dart';
import '../../features/history/history_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/email_login_screen.dart';
import '../../features/onboarding/invite_code_screen.dart';
import '../../features/onboarding/language_select_screen.dart';
import '../../features/onboarding/login_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/survey_screen.dart';
import '../../features/onboarding/tutorial_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/legal/terms_screen.dart';
import '../../features/settings/faq_screen.dart';
import '../../features/settings/goals_screen.dart';
import '../../features/settings/plan_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const language = '/language';
  static const login = '/login';
  static const emailLogin = '/login/email';
  static const invite = '/invite';
  static const survey = '/survey';
  static const tutorial = '/tutorial';
  static const home = '/';
  static const diary = '/diary';
  static const history = '/history';
  static const historyDetail = '/history/:id';
  static const settings = '/settings';
  static const faq = '/settings/faq';
  static const plan = '/settings/plan';
  static const goals = '/settings/goals';
  static const privacy = '/legal/privacy';
  static const terms = '/legal/terms';
}

GoRouter buildRouter({
  required bool onboardingDone,
  required bool hasPickedLanguage,
}) {
  // Always start on the brief splash; it picks the next destination.
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.language,
        builder: (_, _) => const LanguageSelectScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.emailLogin,
        builder: (_, state) {
          final signUp = state.extra is bool ? state.extra as bool : false;
          return EmailLoginScreen(startInSignUpMode: signUp);
        },
      ),
      GoRoute(
        path: AppRoutes.goals,
        builder: (_, _) => const GoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        builder: (_, _) => const InviteCodeScreen(),
      ),
      GoRoute(
        path: AppRoutes.survey,
        builder: (_, _) => const SurveyScreen(),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, _) => const TutorialScreen(),
      ),
      GoRoute(
        path: AppRoutes.diary,
        builder: (_, _) => const DiaryEditScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        builder: (_, _) => const HistoryListScreen(),
      ),
      GoRoute(
        path: AppRoutes.historyDetail,
        builder: (_, state) =>
            HistoryDetailScreen(entryId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        builder: (_, _) => const FaqScreen(),
      ),
      GoRoute(
        path: AppRoutes.plan,
        builder: (_, _) => const PlanScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, _) => const TermsScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Not found: ${state.uri}')),
    ),
  );
}
