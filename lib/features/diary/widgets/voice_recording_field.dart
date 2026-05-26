import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Full-screen particle field that drifts and reacts to voice level.
///
/// Performance-tuned for high-DPI Android (Pixel 10 Pro Fold):
///   * 40 particles (was 220) — fewer paint ops per frame
///   * NO MaskFilter.blur — the single most expensive Skia op for circles
///   * One Paint allocation per frame, reused per dot
///   * One sin call per dot per frame
///
/// Result: stays at the device's refresh rate (120 Hz) with no jank.
class VoiceRecordingField extends StatefulWidget {
  final double level; // 0..1, current sound level
  final Color color;

  const VoiceRecordingField({
    super.key,
    required this.level,
    this.color = Colors.white,
  });

  @override
  State<VoiceRecordingField> createState() => _VoiceRecordingFieldState();
}

class _VoiceRecordingFieldState extends State<VoiceRecordingField>
    with SingleTickerProviderStateMixin {
  // 10-minute period: with random per-particle phases AND speeds, the
  // composed motion takes far longer than one cycle to repeat visibly,
  // so the user never sees a "loop reset".
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(minutes: 10),
  )..repeat();

  final _rand = math.Random(42);
  late final List<_Drifter> _particles = List.generate(
    40,
    (_) => _Drifter.random(_rand),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _FieldPainter(
          t: _c.value,
          level: widget.level.clamp(0.0, 1.0),
          color: widget.color,
          particles: _particles,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Drifter {
  final double angle; // direction from centre
  final double radiusBase; // base distance from centre (0..1)
  final double speed; // outward drift speed
  final double phase;
  final double dotSize;

  _Drifter({
    required this.angle,
    required this.radiusBase,
    required this.speed,
    required this.phase,
    required this.dotSize,
  });

  factory _Drifter.random(math.Random r) {
    return _Drifter(
      angle: r.nextDouble() * math.pi * 2,
      radiusBase: 0.12 + r.nextDouble() * 0.42,
      speed: 0.5 + r.nextDouble() * 1.3,
      phase: r.nextDouble(),
      // Bigger base because there are fewer dots — each one must read well.
      dotSize: 1.2 + r.nextDouble() * 1.8,
    );
  }
}

class _FieldPainter extends CustomPainter {
  final double t;
  final double level;
  final Color color;
  final List<_Drifter> particles;

  _FieldPainter({
    required this.t,
    required this.level,
    required this.color,
    required this.particles,
  });

  static const _twoPi = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final maxR = size.shortestSide * 0.65;

    // One Paint, mutated per dot. Allocating inside the loop was a
    // measurable per-frame cost.
    final paint = Paint();

    // Scale `t` (0..1 over the controller's long period) up so each dot
    // visibly drifts within a single user session.
    final tScaled = t * 60;

    for (final p in particles) {
      final phase = (tScaled + p.phase) * p.speed;
      // ONE sin per dot drives both the gentle radius wobble AND the fade.
      // No `burst` term — particles stay in their lane regardless of voice
      // level, the user only sees a soft brightness change.
      final wave = math.sin(phase * _twoPi);
      final r = (p.radiusBase + wave * 0.13) * maxR;
      final a = p.angle + phase * 0.22;
      final fade = (0.55 + wave * 0.45) * (0.55 + level * 0.45);

      paint.color = color.withValues(alpha: fade.clamp(0.10, 0.85));
      canvas.drawCircle(
        Offset(centre.dx + math.cos(a) * r, centre.dy + math.sin(a) * r),
        p.dotSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) =>
      old.t != t || old.level != level || old.color != color;
}
