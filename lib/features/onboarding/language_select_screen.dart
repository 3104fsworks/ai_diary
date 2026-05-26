import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';

/// Shown on the very first launch. Each option is written in its own
/// language, so anyone — regardless of OS locale — can recognise their choice.
class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = AppSettingsScope.of(context);

    const options = [
      _LangOption(locale: Locale('ja'), label: '日本語'),
      _LangOption(locale: Locale('en'), label: 'English'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Language / 言語',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your language',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () async {
                      await settings.setLocale(o.locale);
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.label,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                'You can change this any time in Settings.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangOption {
  final Locale locale;
  final String label;
  const _LangOption({required this.locale, required this.label});
}
