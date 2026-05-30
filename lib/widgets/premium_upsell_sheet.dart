import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Displays the premium upsell bottom sheet.
///
/// Call this when:
///   • A free user (trial expired) tries to generate or access AI Radio.
///   • A free user reaches the weekly AI-generation limit (3/week).
///
/// ```dart
/// await PremiumUpsellSheet.show(context);
/// ```
class PremiumUpsellSheet {
  PremiumUpsellSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UpsellSheetContent(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _UpsellSheetContent extends StatelessWidget {
  const _UpsellSheetContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF12121C) : const Color(0xFFF6F6FB);
    final cardBg = isDark ? const Color(0xFF1A1A28) : Colors.white;
    final accent = theme.colorScheme.primary; // purple

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Let the sheet be tall enough on small screens
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Drag handle ──────────────────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Radio visual card ────────────────────────────────────
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background: dark gradient
                    Positioned.fill(
                      child: CustomPaint(painter: _RadioBgPainter(accent)),
                    ),
                    // Radio wave arcs
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _RadioWavePainter(accent),
                    ),
                    // Center: mic/radio icon inside circle
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cardBg.withValues(alpha: 0.85),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.radio_outlined,
                        size: 28,
                        color: accent,
                      ),
                    ),
                    // Lock overlay (top-right of the orb)
                    Positioned(
                      top: 48,
                      right: 68,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sheetBg,
                          border: Border.all(
                              color: accent.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Icon(Icons.lock_outline, size: 14, color: accent),
                      ),
                    ),
                    // Premium badge (bottom-right)
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: accent.withValues(alpha: 0.12),
                          border: Border.all(
                              color: accent.withValues(alpha: 0.4), width: 1),
                        ),
                        child: Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accent,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Main copy ────────────────────────────────────────────
              Text(
                '今週も、あなただけの\n「AIラジオ」の準備ができています。',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // ── Body ─────────────────────────────────────────────────
              Text(
                '14日間のフル機能体験期間が終了しました。'
                '今週蓄積されたあなたの日記から、AIが新しいラジオ番組のスクリプトを生成しています。\n\n'
                'プレミアムプランに移行すると、この番組をすぐに再生し、'
                'これからも週末の特別な振り返り時間をお過ごしいただけます。',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 32),

              // ── Primary CTA ──────────────────────────────────────────
              _GradientButton(
                label: 'プランを選んで、今週のラジオを聴く',
                accent: accent,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.plan);
                },
              ),
              const SizedBox(height: 20),

              // ── Secondary link ───────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    '無料プラン（AIラジオなし・AI生成週3回）で続ける',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.55),
                      decoration: TextDecoration.underline,
                      decorationColor: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.3),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              accent,
              Color.lerp(accent, const Color(0xFF6CF0C2), 0.35)!,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline,
                size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painters
// ─────────────────────────────────────────────────────────────────────────────

/// Dark gradient background for the radio visual card.
class _RadioBgPainter extends CustomPainter {
  final Color accent;
  _RadioBgPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, 0.1),
        radius: 0.9,
        colors: [
          accent.withValues(alpha: 0.12),
          accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_RadioBgPainter old) => false;
}

/// Concentric radio-wave arcs radiating from the center.
class _RadioWavePainter extends CustomPainter {
  final Color accent;
  _RadioWavePainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 1; i <= 4; i++) {
      final radius = 30.0 + i * 22.0;
      final alpha = (0.35 - i * 0.07).clamp(0.04, 0.35);
      final paint = Paint()
        ..color = accent.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Draw arcs (top-left and top-right quadrant only for radio feel)
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -math.pi * 0.85,
        math.pi * 0.7,
        false,
        paint,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RadioWavePainter old) => false;
}
