import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_settings.dart';
import '../../app/router/app_router.dart';
import '../diary/widgets/particle_orb.dart';

/// Brief opening animation — Apple-Watch-pairing feel, but short enough
/// to never feel like a stall. Particle orb pulses gently for ~1.1s, then
/// we hand off to whichever screen the app should resume at.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _entry,
    curve: Curves.easeOutCubic,
  ).drive(Tween(begin: 0.6, end: 1.0));

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _entry,
    curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    // Total dwell = ~1100ms. After that, route to the appropriate page.
    Future.delayed(const Duration(milliseconds: 1100), _handoff);
  }

  void _handoff() {
    if (!mounted) return;
    final s = AppSettingsScope.of(context);
    final next = !s.hasPickedLanguage
        ? AppRoutes.language
        : (s.onboardingDone ? AppRoutes.home : AppRoutes.login);
    context.go(next);
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  child: ParticleOrb(
                    size: 200,
                    intensity: 0.7,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI Journal',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
