import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/theme/app_theme.dart';

/// Google's official sign-in button style — light bg, charcoal text,
/// and the multi-colour Google "G" mark (rendered from an SVG asset for
/// pixel-perfect brand colours). Inverts cleanly for dark mode.
class GoogleSignInButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isLight = brightness == Brightness.light;
    final bg = isLight ? Colors.white : const Color(0xFF131314);
    final fg = isLight ? const Color(0xFF1F1F1F) : const Color(0xFFE3E3E3);
    final border = isLight ? const Color(0xFFDADCE0) : const Color(0xFF8E918F);

    return SizedBox(
      height: 56,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: border),
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rendered from the asset SVG — the brand colours stay correct
                // even in dark mode because the G's palette is locked in the file.
                SvgPicture.asset(
                  'assets/icons/google_g.svg',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Arial',
                    color: fg,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    letterSpacing: 0.2,
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
