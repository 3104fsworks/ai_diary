// voice_button.dart — legacy inline voice widget, no longer used.
//
// The main voice input entry point is now VoiceRecordingScreen (full-screen,
// Whisper-based, 2-minute limit). This file is kept as a placeholder so
// the widget can be repurposed for future features (e.g. short-note recording
// from the home screen) without re-creating the file scaffolding.
//
// The original speech_to_text implementation was removed when we switched to
// OpenAI Whisper in version 1.0.0+10 (speech_to_text dropped from pubspec).

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'particle_orb.dart';

/// Minimal voice-action button — visual stub only.
/// Wire up [onTap] to open [VoiceRecordingScreen] when needed.
class VoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const VoiceButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(
          child: ParticleOrb(
            size: 240,
            intensity: 0.4,
            color: theme.colorScheme.primary,
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic_none_outlined, size: 22),
                const SizedBox(width: 10),
                Text(label, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
