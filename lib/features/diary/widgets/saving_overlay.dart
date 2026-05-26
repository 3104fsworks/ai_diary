import 'package:flutter/material.dart';

import 'particle_orb.dart';

/// "AI is composing your day" overlay shown briefly after Done.
class SavingOverlay extends StatelessWidget {
  final String label;
  const SavingOverlay({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.94),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ParticleOrb(
              size: 200,
              intensity: 1.0,
              converging: true,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
