// Generates a placeholder app_icon.png + app_icon_foreground.png for
// flutter_launcher_icons. Run with:
//   dart run tool/generate_placeholder_icon.dart
//
// Output: assets/icon/app_icon.png and assets/icon/app_icon_foreground.png
//
// Replace these PNGs with a real design later — flutter_launcher_icons
// will regenerate every platform-specific icon from the new file.

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;

  // Background palette — matches the app's deep navy accent.
  final navy = img.ColorRgb8(31, 42, 68);
  final ivory = img.ColorRgb8(250, 250, 247);

  // --- 1. Full square icon (bg + logo) for Android / iOS legacy ---
  final base = img.Image(width: size, height: size);
  img.fill(base, color: navy);
  _drawLogo(base, ivory);
  File('assets/icon/app_icon.png').writeAsBytesSync(img.encodePng(base));

  // --- 2. Foreground-only PNG for Android 8+ adaptive icons ---
  // Transparent bg, logo centred. flutter_launcher_icons composites this
  // over `adaptive_icon_background` configured in pubspec.yaml.
  final foreground = img.Image(width: size, height: size, numChannels: 4);
  _drawLogo(foreground, ivory);
  File('assets/icon/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  // --- 3. Splash logo (smaller, transparent bg) for flutter_native_splash ---
  final splash = img.Image(width: size, height: size, numChannels: 4);
  _drawLogo(splash, navy);
  File('assets/icon/splash_logo.png').writeAsBytesSync(img.encodePng(splash));

  final splashDark = img.Image(width: size, height: size, numChannels: 4);
  _drawLogo(splashDark, ivory);
  File('assets/icon/splash_logo_dark.png')
      .writeAsBytesSync(img.encodePng(splashDark));

  stdout.writeln('Placeholder icons written to assets/icon/.');
}

/// Concentric rings + centre dot — abstract enough to read as a "moment"
/// or a calm pulse on the home screen.
void _drawLogo(img.Image canvas, img.Color stroke) {
  final cx = canvas.width ~/ 2;
  final cy = canvas.height ~/ 2;
  // Outer ring
  _drawRing(canvas, cx, cy, 320, 28, stroke);
  // Inner ring
  _drawRing(canvas, cx, cy, 200, 20, stroke);
  // Centre dot
  img.fillCircle(canvas, x: cx, y: cy, radius: 70, color: stroke);
}

/// Draws a filled ring (annulus) by stacking many concentric circle outlines.
void _drawRing(img.Image canvas, int cx, int cy, int radius, int thickness,
    img.Color color) {
  for (var i = 0; i < thickness; i++) {
    img.drawCircle(
      canvas,
      x: cx,
      y: cy,
      radius: radius - i,
      color: color,
    );
  }
}
