import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 5-bar waveform that pulses with the user's voice level — a clear
/// "I'm listening" signal. Bars never collapse to zero, so the user
/// always sees activity (and trusts the mic is still on) even during
/// short silences.
class VoiceWaveform extends StatefulWidget {
  final double level; // 0..1, current sound level from speech_to_text
  final Color color;
  final double width;
  final double height;

  const VoiceWaveform({
    super.key,
    required this.level,
    required this.color,
    this.width = 120,
    this.height = 28,
  });

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return CustomPaint(
            painter: _WavePainter(
              phase: _c.value,
              level: widget.level.clamp(0.0, 1.0),
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final double level;
  final Color color;

  _WavePainter({
    required this.phase,
    required this.level,
    required this.color,
  });

  static const _barCount = 5;
  static const _barWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final spacing = (size.width - _barCount * _barWidth) / (_barCount + 1);
    final maxBarHeight = size.height;
    final minBarHeight = size.height * 0.18;
    final paint = Paint()..color = color;

    for (var i = 0; i < _barCount; i++) {
      // Each bar oscillates with a phase offset so the wave looks alive.
      final wave = math.sin((phase + i * 0.18) * math.pi * 2);
      // Combine the live `level` (volume) and the idle wave to keep motion
      // even when the user is silent.
      final amplitude = 0.35 + level * 0.65;
      final factor = (0.5 + 0.5 * wave) * amplitude;
      final h =
          minBarHeight + (maxBarHeight - minBarHeight) * factor.clamp(0.0, 1.0);

      final x = spacing + i * (_barWidth + spacing);
      final rect = Rect.fromLTWH(x, (size.height - h) / 2, _barWidth, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.phase != phase || old.level != level || old.color != color;
}
