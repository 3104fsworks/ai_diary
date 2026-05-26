import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../app/theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/voice_recording_field.dart';

/// Returned by [VoiceRecordingScreen]. The diary screen takes this back and
/// merges it into its text field + raw voice memo.
class VoiceRecordingResult {
  final String transcript;
  const VoiceRecordingResult(this.transcript);
}

/// Full-screen "talk to your day" mode.
///
/// Listening AUTO-RESTARTS whenever the OS speech engine drops out — both
/// via the engine's status callbacks AND via a 1-second watchdog timer.
/// Only the Done button actually ends the session.
class VoiceRecordingScreen extends StatefulWidget {
  final String initialTranscript;

  const VoiceRecordingScreen({
    super.key,
    this.initialTranscript = '',
  });

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  final _speech = stt.SpeechToText();
  String _transcript = '';
  String _partial = '';
  double _level = 0.0;
  bool _listening = false;
  bool _initialised = false;
  /// True until the user taps Done. While true, any drop in the engine's
  /// listening state triggers a restart.
  bool _userActive = true;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _transcript = widget.initialTranscript;
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _userActive = false;
    _watchdog?.cancel();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final ok = await _speech.initialize(
      onStatus: _onStatus,
      onError: (_) {
        if (mounted && _userActive) _scheduleRestart();
      },
    );
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is unavailable on this device.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    _initialised = true;
    // Watchdog: belt-and-braces — even if every status callback misfires,
    // this loop will restart listening whenever it has actually stopped.
    _watchdog = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_userActive) return;
      if (!_speech.isListening) _scheduleRestart();
    });
    await _startListening();
  }

  void _onStatus(String status) {
    if (!mounted) return;
    final isListening = status == 'listening';
    if (_listening != isListening) {
      setState(() => _listening = isListening);
    }
    if ((status == 'notListening' || status == 'done') && _userActive) {
      _scheduleRestart();
    }
  }

  bool _restartQueued = false;
  void _scheduleRestart() {
    if (_restartQueued) return;
    _restartQueued = true;
    Future.delayed(const Duration(milliseconds: 400), () async {
      _restartQueued = false;
      if (!mounted || !_userActive || !_initialised) return;
      if (_speech.isListening) return;
      await _startListening();
    });
  }

  Future<void> _startListening() async {
    if (!_initialised || !_userActive) return;
    final localeCode = Localizations.localeOf(context).languageCode;
    final localeId = localeCode == 'ja' ? 'ja_JP' : 'en_US';

    // Flush any in-progress partial into the committed transcript so the
    // restart does not lose what the user just said.
    if (_partial.isNotEmpty) {
      setState(() {
        _transcript =
            _transcript.isEmpty ? _partial : '$_transcript\n$_partial';
        _partial = '';
      });
    }

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
          localeId: localeId,
          autoPunctuation: true,
          listenFor: const Duration(hours: 1),
          pauseFor: const Duration(hours: 1),
        ),
        onSoundLevelChange: (level) {
          if (!mounted) return;
          final normalised = ((level + 2) / 12).clamp(0.0, 1.0);
          setState(() => _level = normalised);
        },
        onResult: (r) {
          if (!mounted) return;
          if (r.finalResult && r.recognizedWords.isNotEmpty) {
            setState(() {
              _transcript = _transcript.isEmpty
                  ? r.recognizedWords
                  : '$_transcript\n${r.recognizedWords}';
              _partial = '';
            });
          } else {
            setState(() => _partial = r.recognizedWords);
          }
        },
      );
    } catch (_) {
      if (mounted && _userActive) _scheduleRestart();
    }
  }

  Future<void> _finish() async {
    _userActive = false;
    _watchdog?.cancel();
    await _speech.stop();
    if (!mounted) return;
    final combined = _partial.isEmpty
        ? _transcript
        : (_transcript.isEmpty ? _partial : '$_transcript\n$_partial');
    Navigator.of(context).pop(VoiceRecordingResult(combined));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? Colors.black : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = isDark
        ? const Color(0xFFB0B0B0)
        : const Color(0xFF757575);
    // Ivory accent fades into white — boost to a richer caramel so the
    // particles stay visible on a white background.
    final accent = theme.colorScheme.primary;
    final particleColor = (!isDark && accent == AppColors.accentIvory)
        ? const Color(0xFFB89E5D)
        : accent;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Where the Done button sits — keep transcript clear of it.
    final reservedBottom = bottomInset + 32 + 56 + 16;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // 1) Particle field — covers the whole screen.
            Positioned.fill(
              child: VoiceRecordingField(
                level: _listening ? _level : 0.0,
                color: particleColor,
              ),
            ),

            // 2) Transcript & "Listening..." overlay, centred above the button.
            Positioned(
              left: 32,
              right: 32,
              top: 0,
              bottom: reservedBottom,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_transcript.isEmpty && _partial.isEmpty)
                        Text(
                          _listening ? l.diaryVoiceListening : '',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            letterSpacing: 3,
                          ),
                        )
                      else
                        Text(
                          _partial.isEmpty
                              ? _transcript
                              : (_transcript.isEmpty
                                  ? _partial
                                  : '$_transcript\n$_partial'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.95),
                            fontSize: 22,
                            height: 1.6,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 3) Done button — centred horizontally at the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 32 + bottomInset,
              child: Center(
                child: SizedBox(
                  width: 200,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l.diaryDone,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
