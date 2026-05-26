# App icon & splash assets

Drop the final brand assets here, then run the generator commands.

## Required files

| File | Purpose | Size | Notes |
|---|---|---|---|
| `app_icon.png` | Main launcher icon (Android + iOS) | **1024×1024** | Square, no alpha. PNG with the full app icon design (logo + background). |
| `app_icon_foreground.png` | Android adaptive icon foreground | **1024×1024** | Transparent background. The logo only — Android will composite it on `#FAFAF7`. Keep the logo within the safe zone (~660×660 centered). |
| `splash_logo.png` | Native splash (light mode) | **512×512** or larger | Logo only on transparent background. Background colour is configured in pubspec (`#FAFAF7`). |
| `splash_logo_dark.png` | Native splash (dark mode) | Same as above | Same logo, white/light tinted for dark backgrounds. |

## Generate the platform assets

After placing the files above, run from the project root:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

This writes the generated icons / splash images into:
- `android/app/src/main/res/mipmap-*/`
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/app/src/main/res/drawable*/launch_background.xml` (splash)

You only need to regenerate when the source images change.

## Brand colours

- Off-white / cream: `#FAFAF7` (used for app icon background + light splash)
- Dark / charcoal:   `#121212` (used for dark splash)
- Default accent (navy): `#1F2A44`

## Until your final logo arrives

Until then, the app falls back to:
- Default Flutter icon on the launcher
- A small flash of the system default colour as splash

The configuration is already wired — just drop the PNGs and run the commands.
