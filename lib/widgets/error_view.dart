import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Standard "something went wrong" panel — used as the fallback in
/// FutureBuilder / async UI when a load fails.
/// Tone: quiet, never blaming the user. A retry button when applicable.
class ErrorView extends StatelessWidget {
  final String? title;
  final String? detail;
  final VoidCallback? onRetry;

  const ErrorView({
    super.key,
    this.title,
    this.detail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 36,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? l.commonError,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.commonRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
