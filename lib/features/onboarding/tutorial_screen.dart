import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../core/notifications/diary_reminder_service.dart';
import '../../l10n/generated/app_localizations.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _requestingPermission = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _completeOnboarding() {
    AppSettingsScope.of(context).setOnboardingDone(true);
    context.go(AppRoutes.home);
  }

  /// Requests notification permission, schedules daily reminder at 21:00,
  /// then completes onboarding.
  Future<void> _allowNotificationsAndComplete() async {
    if (_requestingPermission) return;
    setState(() => _requestingPermission = true);
    try {
      final granted =
          await DiaryReminderService.instance.requestPermission();
      if (granted && mounted) {
        final settings = AppSettingsScope.of(context);
        await settings.setDiaryReminderEnabled(true);
        await DiaryReminderService.instance.scheduleDaily(
          hour: settings.diaryReminderHour,
          enabled: true,
        );
      }
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
    if (!mounted) return;
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // The notification-permission page is a special widget (not _TutorialPage).
    final pages = <Widget>[
      _TutorialPage(title: l.tutorialTitle1, body: l.tutorialBody1),
      _TutorialPage(title: l.tutorialTitle2, body: l.tutorialBody2),
      _TutorialPage(title: l.tutorialTitle3, body: l.tutorialBody3),
      _NotifPermissionPage(
        onAllow: _allowNotificationsAndComplete,
        loading: _requestingPermission,
      ),
    ];

    final isLastPage = _page == pages.length - 1;
    // On the notification page the bottom button becomes "あとで設定する".
    final bottomLabel = isLastPage ? 'あとで設定する' : l.surveyNext;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                l.tutorialSkip,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton(
                // Last page: "あとで設定する" → skip notifications → complete.
                // Other pages: advance to next page.
                onPressed: isLastPage
                    ? _completeOnboarding
                    : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                style: isLastPage
                    ? ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.textTheme.bodySmall?.color,
                        elevation: 0,
                        side: BorderSide(color: theme.dividerColor),
                      )
                    : null,
                child: Text(bottomLabel),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TutorialPage extends StatelessWidget {
  final String title;
  final String body;
  const _TutorialPage({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: theme.textTheme.displayLarge),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification permission page (tutorial step 4) ────────────────────────────

class _NotifPermissionPage extends StatelessWidget {
  final VoidCallback onAllow;
  final bool loading;
  const _NotifPermissionPage({required this.onAllow, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bell icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            '毎日の日記リマインダー',
            style: theme.textTheme.displayLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '毎晩21時に「今日はどんな1日でしたか？」とやさしく声をかけます。\n\n'
            '後から設定画面でいつでも時刻の変更・オフにできます。',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          // Primary action — allow notifications
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading ? null : onAllow,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('通知をオンにする'),
            ),
          ),
        ],
      ),
    );
  }
}
