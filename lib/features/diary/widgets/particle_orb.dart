import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A light-particle orb rendered with CustomPainter.
/// Cheap, smooth, gives the "Apple Watch pairing" near-future feel.
class ParticleOrb extends StatefulWidget {
  final double size;
  final double intensity; // 0..1 — voice volume or "AI thinking" energy
  final Color color;
  final bool converging; // when true, particles pull toward center
  final int particleCount;

  const ParticleOrb({
    super.key,
    this.size = 120,
    this.intensity = 0.6,
    this.color = Colors.white,
    this.converging = false,
    this.particleCount = 80,
  });

  @override
  State<ParticleOrb> createState() => _ParticleOrbState();
}

class _ParticleOrbState extends State<ParticleOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rand = math.Random(7);
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    // Long period so the user never catches the loop reset. Particles have
    // per-instance phase + speed, so composed motion never visibly repeats.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(minutes: 10),
    )..repeat();
    _particles = List.generate(
      widget.particleCount,
      (_) => _Particle.random(_rand),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return CustomPaint(
            painter: _OrbPainter(
              t: _c.value,
              particles: _particles,
              intensity: widget.intensity,
              color: widget.color,
              converging: widget.converging,
            ),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double radius;
  final double speed;
  final double phase;
  final double dotSize;

  _Particle({
    required this.angle,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.dotSize,
  });

  factory _Particle.random(math.Random r) {
    return _Particle(
      angle: r.nextDouble() * math.pi * 2,
      // Wider radius spread so dots reach further out than before.
      radius: 0.25 + r.nextDouble() * 0.85,
      speed: 0.6 + r.nextDouble() * 1.8,
      phase: r.nextDouble(),
      // Bigger dot variation — some tiny sparkles, some larger glints.
      dotSize: 1.0 + r.nextDouble() * 2.6,
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;
  final double intensity;
  final Color color;
  final bool converging;

  _OrbPainter({
    required this.t,
    required this.particles,
    required this.intensity,
    required this.color,
    required this.converging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Controller is now 10-min; scale up so per-frame motion matches the
    // original 4-second-loop feel.
    final tScaled = t * 150;

    for (final p in particles) {
      final phase = (tScaled + p.phase) * p.speed;
      // Slightly wider wave amplitude so motion is visible at a glance.
      final wave = math.sin(phase * math.pi * 2) * 0.20;
      final convergeFactor =
          converging ? math.max(0, 1 - tScaled * 0.04) : 1.0;
      final r = (p.radius + wave) * maxR * 0.98 * convergeFactor *
          (0.65 + intensity * 0.55);
      final a = p.angle + phase * 0.4;
      final pos = Offset(
        center.dx + math.cos(a) * r,
        center.dy + math.sin(a) * r,
      );

      // Stronger minimum opacity → particles are always perceptible,
      // never near-invisible during quiet moments.
      final fade =
          (0.65 + math.sin(phase * math.pi * 2 + p.phase) * 0.35) *
              (0.45 + intensity * 0.55);
      final paint = Paint()
        ..color = color.withValues(alpha: fade.clamp(0.10, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6);
      canvas.drawCircle(pos, p.dotSize * (0.9 + intensity * 0.7), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}
