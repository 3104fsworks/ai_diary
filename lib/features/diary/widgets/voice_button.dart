import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../app/theme/app_theme.dart';
import 'particle_orb.dart';

/// Tap to "talk" — uses platform speech recognition (Apple's SFSpeechRecognizer
/// on iOS, Google Speech Services on Android). Surfaces partial results
/// live and emits the final transcript on stop.
class VoiceButton extends StatefulWidget {
  final String label;
  final String localeId;

  /// Called once recognition stops, with the final transcript.
  final ValueChanged<String>? onTranscript;

  /// Called with partial results during recognition — useful for live preview.
  final ValueChanged<String>? onPartial;

  const VoiceButton({
    super.key,
    required this.label,
    this.localeId = 'ja_JP',
    this.onTranscript,
    this.onPartial,
  });

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton> {
  final _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;
  bool _listening = false;
  double _volume = 0.4;
  String _live = '';

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _available = await _speech.initialize(
      onStatus: (s) {
        if (s == 'notListening' || s == 'done') {
          if (mounted && _listening) {
            setState(() => _listening = false);
            if (_live.isNotEmpty) widget.onTranscript?.call(_live);
          }
        }
      },
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
    );
    _initialized = true;
  }

  Future<void> _toggle() async {
    await _ensureInit();
    if (!_available) {
      _showUnavailable();
      return;
    }
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      if (_live.isNotEmpty) widget.onTranscript?.call(_live);
      return;
    }
    setState(() {
      _live = '';
      _listening = true;
    });
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        localeId: widget.localeId,
      ),
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Normalize roughly to 0..1.
        final v = ((level + 2) / 12).clamp(0.0, 1.0);
        setState(() => _volume = 0.35 + v * 0.65);
      },
      onResult: (r) {
        if (!mounted) return;
        setState(() => _live = r.recognizedWords);
        widget.onPartial?.call(r.recognizedWords);
      },
    );
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Speech recognition is unavailable on this device.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (_listening)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: ParticleOrb(
                      size: 240,
                      intensity: _volume,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: theme.dividerColor),
                  color: _listening
                      ? theme.colorScheme.primary.withValues(alpha: 0.06)
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _listening
                          ? Icons.stop_outlined
                          : Icons.mic_none_outlined,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(widget.label, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_listening && _live.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _live,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
