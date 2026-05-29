import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';
import '../../features/diary/widgets/particle_orb.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/app_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppLogo(size: 56),
            const SizedBox(height: 10),
            Text(
              l.appTitleLine,
              style: theme.textTheme.headlineMedium?.copyWith(
                letterSpacing: 2,
              ),
            ),
            const Spacer(flex: 3),
            // Particle orb + circle, layered.
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient particle field behind the button —
                  // Apple-Watch-pairing style, very low intensity.
                  IgnorePointer(
                    child: ParticleOrb(
                      size: 280,
                      intensity: 0.45,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _PrimaryCircleButton(
                    label: l.homeWriteToday,
                    onTap: () => context.push(AppRoutes.diary),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _SecondaryButton(
                label: l.homeWeeklyRadio,
                onTap: () => context.push(AppRoutes.weeklyRadio),
                icon: Icons.radio_outlined,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      label: l.homeViewPast,
                      onTap: () => context.push(AppRoutes.history),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      label: l.homeSettings,
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SecondaryButton(
                      label: l.homeHelp,
                      onTap: () => context.push(AppRoutes.faq),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// The main "write today" call to action. Designed to feel premium:
/// a radial gradient gives the disc subtle depth, soft layered shadows
/// lift it off the page, and a tap dims-and-scales the disc briefly.
class _PrimaryCircleButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryCircleButton({required this.label, required this.onTap});

  @override
  State<_PrimaryCircleButton> createState() => _PrimaryCircleButtonState();
}

class _PrimaryCircleButtonState extends State<_PrimaryCircleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    // Slight lighter/darker variants for the radial gradient.
    final highlight = Color.lerp(accent, Colors.white, 0.18)!;
    final shadow = Color.lerp(accent, Colors.black, 0.20)!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.25, -0.35),
              radius: 0.95,
              colors: [highlight, accent, shadow],
              stops: const [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              // Long soft shadow → "floating" feel.
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              // Tight contact shadow → grounded, premium.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            // Editorial typography to match the button's premium feel —
            // generous letter-spacing, light weight, restrained size.
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Arial',
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w400,
                fontSize: 19,
                letterSpacing: 5,
                height: 1.5,
                // Subtle text shadow lifts the type off the gradient.
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  const _SecondaryButton({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
