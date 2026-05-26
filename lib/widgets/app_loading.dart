import 'package:flutter/material.dart';

import '../features/diary/widgets/particle_orb.dart';

/// On-brand loading indicator — a small particle orb instead of the
/// default Material spinner. Reads as "the app is breathing, just
/// gathering things" rather than a generic wait.
class AppLoading extends StatelessWidget {
  final double size;
  final String? label;
  const AppLoading({super.key, this.size = 80, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IgnorePointer(
            child: ParticleOrb(
              size: size,
              intensity: 0.65,
              color: theme.colorScheme.primary,
              particleCount: 30,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(label!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
