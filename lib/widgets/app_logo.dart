import 'dart:math' as math;

import 'package:flutter/material.dart';

/// AI Journal brand mark.
///
/// A solid cream sphere at the centre, surrounded by concentric particle
/// rings that grow denser along the horizontal axis — giving the mark
/// subtle audio-wave "spikes" on the left and right. Inspired by the
/// app's voice-recording particle field; this is the same language at
/// rest.
class AppLogo extends StatelessWidget {
  final double size;
  /// Override the core sphere colour. Defaults to a warm cream.
  final Color? coreColor;
  /// Override the particle colour. Defaults to coreColor at low opacity.
  final Color? particleColor;

  const AppLogo({
    super.key,
    this.size = 56,
    this.coreColor,
    this.particleColor,
  });

  @override
  Widget build(BuildContext context) {
    final core = coreColor ?? const Color(0xFFE9E2CC);
    final particles = particleColor ?? core;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(
          coreColor: core,
          particleColor: particles,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color coreColor;
  final Color particleColor;

  _LogoPainter({required this.coreColor, required this.particleColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // 1. Soft halo behind the core for depth.
    final glowR = maxR * 0.34;
    canvas.drawCircle(
      c,
      glowR,
      Paint()
        ..color = coreColor.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Solid central sphere.
    final coreR = maxR * 0.28;
    canvas.drawCircle(c, coreR, Paint()..color = coreColor);

    // 3. Concentric particle rings.
    // Rings start just outside the core and fade out toward the edges.
    // Each ring's dot density is modulated by |cos(angle)| so that the
    // horizontal axis is denser — creating the lateral "spike" feel.
    const rings = 18;
    for (var ring = 0; ring < rings; ring++) {
      // Radius spans from just outside core to ~98% of maxR.
      final t = ring / (rings - 1);
      final r = coreR * 1.15 + (maxR * 0.95 - coreR * 1.15) * t;

      // More dots on outer rings (denser arc).
      final dotCount = 56 + ring * 18;

      // Outer rings dim down.
      final ringAlphaBase = (1.0 - t * 0.7).clamp(0.05, 1.0);

      for (var i = 0; i < dotCount; i++) {
        final angle = (i / dotCount) * math.pi * 2;

        // Horizontal emphasis: |cos(angle)| peaks at left/right.
        final lateral = math.pow(math.cos(angle).abs(), 1.8).toDouble();

        // Vertical attenuation: top/bottom rings have fewer "lit" dots.
        // Skip a dot probabilistically based on lateral weight.
        final lit = 0.25 + lateral * 0.75;
        // Stable per-dot pseudo-random based on ring+i.
        final pseudo = ((ring * 73 + i * 31) % 100) / 100.0;
        if (pseudo > lit + 0.15) continue;

        final dotSize = 0.7 + lateral * 1.6 + t * 0.4;
        final alpha = ringAlphaBase * (0.45 + lateral * 0.55);

        final px = c.dx + math.cos(angle) * r;
        final py = c.dy + math.sin(angle) * r;
        canvas.drawCircle(
          Offset(px, py),
          dotSize * (size.shortestSide / 200),
          Paint()
            ..color = particleColor.withValues(alpha: alpha.clamp(0.05, 1.0))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) =>
      old.coreColor != coreColor || old.particleColor != particleColor;
}
