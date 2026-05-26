import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_settings.dart';
import 'router/app_router.dart';
import 'service_locator.dart';
import 'theme/app_theme.dart';

class AiDiaryApp extends StatefulWidget {
  final AppSettings settings;
  final ServiceLocator services;
  const AiDiaryApp({
    super.key,
    required this.settings,
    required this.services,
  });

  @override
  State<AiDiaryApp> createState() => _AiDiaryAppState();
}

class _AiDiaryAppState extends State<AiDiaryApp> {
  late final _router = buildRouter(
    onboardingDone: widget.settings.onboardingDone,
    hasPickedLanguage: widget.settings.hasPickedLanguage,
  );

  @override
  Widget build(BuildContext context) {
    return Services(
      locator: widget.services,
      child: AppSettingsScope(
        settings: widget.settings,
        child: ListenableBuilder(
          listenable: widget.settings,
          builder: (_, _) {
            return MaterialApp.router(
              title: 'AI Journal',
              debugShowCheckedModeBanner: false,
              routerConfig: _router,
              themeMode: widget.settings.themeMode,
              theme: AppTheme.light(accent: widget.settings.accent),
              darkTheme: AppTheme.dark(accent: widget.settings.accent),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: widget.settings.localeOverride,
              builder: (context, child) {
                // Apply the user-selected text scale on top of the OS one,
                // capped so the layout doesn't break at extreme sizes.
                final base = MediaQuery.of(context).textScaler;
                final userScale = widget.settings.fontScale.scale;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: base.clamp(
                      minScaleFactor: userScale,
                      maxScaleFactor: userScale,
                    ),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
