import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Speech-bubble tooltip that floats above the voice button on first use.
/// Auto-dismisses after [autoDismiss], or when the user taps anywhere.
class VoiceTooltip extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final Duration autoDismiss;

  const VoiceTooltip({
    super.key,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.autoDismiss = const Duration(seconds: 6),
  });

  @override
  State<VoiceTooltip> createState() => _VoiceTooltipState();
}

class _VoiceTooltipState extends State<VoiceTooltip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _c, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.1), end: Offset.zero).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.autoDismiss, () {
      if (!mounted) return;
      _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _c.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: _dismiss,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.92),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Downward-pointing arrow / triangle
              CustomPaint(
                size: const Size(18, 10),
                painter: _TrianglePainter(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) => old.color != color;
}
