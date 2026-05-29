import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../app/app_settings.dart';
import '../../app/theme/app_colors.dart';
import '../../core/ai/whisper_transcription_service.dart';
import '../../data/models/voice_metadata.dart';
import '../../l10n/generated/app_localizations.dart';
import 'widgets/voice_recording_field.dart';

// ---------------------------------------------------------------------------
// Result type — carried back to DiaryEditScreen after recording + transcription
// ---------------------------------------------------------------------------

/// Returned by [VoiceRecordingScreen]. Carries the Whisper transcript,
/// the local audio file path (for history playback + time-capsule), and
/// voice characteristics used by the weekly AI radio BGM logic.
class VoiceRecordingResult {
  final String transcript;

  /// Absolute path to the .m4a file on the device.
  /// Null when recording was cancelled before stopping or an error occurred.
  final String? audioFilePath;

  /// Voice characteristics computed from amplitude samples during recording.
  final VoiceMetadata? voiceMetadata;

  const VoiceRecordingResult(
    this.transcript, {
    this.audioFilePath,
    this.voiceMetadata,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen recording mode.
///
/// UX flow:
///   1. Tap the mic FAB → this screen pushes.
///   2. Permission check → if denied, pop with an explanation.
///   3. OpenAI key check → if missing, show a dialog and pop.
///   4. Countdown ring (max 2 minutes) + amplitude visualiser.
///   5. User taps Stop (or 2 min elapses) → recording stops.
///   6. "文字起こし中…" spinner → Whisper API call.
///   7. Transcript returned via Navigator.pop(VoiceRecordingResult(...)).
///
/// Why Whisper instead of on-device STT?
///   Android's SpeechRecognizer times out on silence and silently drops the
///   in-flight partial buffer, causing sentences to disappear mid-dictation.
///   Whisper processes the entire audio file post-recording, so pauses during
///   speech are handled correctly. Cost: $0.006/min → ≤ $0.012 per entry.
class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen>
    with SingleTickerProviderStateMixin {
  // 2-minute hard cap matches the product's "journal in one breath" concept
  // and bounds the Whisper cost to $0.012 per entry at worst.
  static const _maxSeconds = 120;

  final _recorder = AudioRecorder();

  // Recording state
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _audioFilePath;
  int _remainingSeconds = _maxSeconds;

  // Amplitude tracking — sampled every 500 ms during recording
  final List<double> _amplitudeSamples = [];
  double _currentAmplitude = 0.0; // drives the particle visualiser

  Timer? _countdownTimer;
  Timer? _amplitudeSampler;

  // Pulse animation for the recording indicator dot
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeSampler?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Bootstrap — permissions → key check → start recording
  // -------------------------------------------------------------------------

  Future<void> _bootstrap() async {
    if (!mounted) return;

    // Web is not supported (record package is native-only).
    if (kIsWeb) {
      _popWithError('音声録音は Web では利用できません。');
      return;
    }

    // Microphone permission
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      _popWithError('マイクへのアクセスが拒否されました。OS設定からマイクを許可してください。');
      return;
    }

    if (!mounted) return;

    await _startRecording();
  }


  void _popWithError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.of(context).pop();
  }

  // -------------------------------------------------------------------------
  // Recording lifecycle
  // -------------------------------------------------------------------------

  Future<void> _startRecording() async {
    // Build a timestamped path inside the app's documents directory.
    final dir = await getApplicationDocumentsDirectory();
    final audioDir =
        Directory('${dir.path}${Platform.pathSeparator}audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final filePath =
        '${audioDir.path}${Platform.pathSeparator}$ts.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000, // 16 kHz is sufficient for voice; saves bandwidth
        numChannels: 1,    // mono — Whisper doesn't benefit from stereo
        bitRate: 64000,    // 64 kbps → ~0.48 MB/min (well within Whisper 25 MB limit)
      ),
      path: filePath,
    );

    _audioFilePath = filePath;
    if (mounted) setState(() => _isRecording = true);

    // Countdown — every second, decrement and auto-stop at zero.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        t.cancel();
        _stopAndTranscribe();
      }
    });

    // Amplitude sampler — feeds the particle visualiser and VoiceMetadata.
    // dBFS range from the record package: typically -160 to 0.
    // We normalise using -60 dBFS as the practical floor (quietest whisper).
    _amplitudeSampler = Timer.periodic(
      const Duration(milliseconds: 500),
      (t) async {
        if (!mounted || !_isRecording) {
          t.cancel();
          return;
        }
        try {
          final amp = await _recorder.getAmplitude();
          final normalised = ((amp.current + 60) / 60).clamp(0.0, 1.0);
          _amplitudeSamples.add(normalised);
          if (mounted) setState(() => _currentAmplitude = normalised);
        } catch (_) {/* transient — ignore */}
      },
    );
  }

  Future<void> _stopAndTranscribe() async {
    if (!_isRecording) return;

    _countdownTimer?.cancel();
    _amplitudeSampler?.cancel();

    final elapsed = _maxSeconds - _remainingSeconds;

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    // Capture context-dependent values BEFORE the first await so we don't
    // access BuildContext across async gaps (use_build_context_synchronously).
    if (!mounted) return;
    final settings = AppSettingsScope.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final stoppedPath = await _recorder.stop();
    // _audioFilePath was set at the start of recording and is the canonical
    // path; stoppedPath is used as a fallback on platforms where stop()
    // returns the finalised path rather than the originally provided one.
    final audioPath = _audioFilePath ?? stoppedPath;

    if (audioPath == null || audioPath.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Compute voice characteristics from amplitude history.
    final metadata = VoiceMetadata.compute(
      amplitudeSamples: _amplitudeSamples,
      totalDurationSeconds: elapsed.clamp(0, _maxSeconds),
    );

    // Call Whisper API.
    String transcript = '';

    try {
      final whisper = WhisperTranscriptionService(
        apiKey: settings.openAiApiKey,
        proxyUrl: settings.proxyBaseUrl,
        appToken: settings.appProxyToken,
      );
      transcript =
          await whisper.transcribe(
            audioPath: audioPath,
            languageCode: localeCode,
          ) ??
              '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '文字起こしエラー: ${e.toString().length > 120 ? '${e.toString().substring(0, 120)}…' : e}',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(
      VoiceRecordingResult(
        transcript,
        audioFilePath: audioPath,
        voiceMetadata: metadata,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? Colors.black : Colors.white;
    final fg = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final muted = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
    final accent = theme.colorScheme.primary;
    final particleColor = (!isDark && accent == AppColors.accentIvory)
        ? const Color(0xFFB89E5D)
        : accent;

    final progress = (_maxSeconds - _remainingSeconds) / _maxSeconds;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isRecording) _stopAndTranscribe();
      },
      child: Scaffold(
        backgroundColor: bg,
        body: Stack(
          children: [
            // ── Background particle field ──────────────────────────────────
            Positioned.fill(
              child: VoiceRecordingField(
                level: _isRecording ? _currentAmplitude : 0.0,
                color: particleColor,
              ),
            ),

            // ── Countdown ring: exactly at screen center ───────────────
            Center(
              child: _buildCountdownRing(progress, fg, muted, accent),
            ),

            // ── Status row: top ────────────────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: _buildStatusRow(l, fg, muted, accent),
                ),
              ),
            ),

            // ── Hint + stop button: bottom ─────────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHint(l, muted),
                    const SizedBox(height: 24),
                    _buildStopButton(l, accent, theme, bottomInset),
                    SizedBox(height: 24 + bottomInset),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(
      AppLocalizations l, Color fg, Color muted, Color accent) {
    if (_isTranscribing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: accent,
            ),
          ),
          const SizedBox(width: 8),
          Text(l.voiceTranscribing,
              style: TextStyle(color: muted, fontSize: 13, letterSpacing: 2)),
        ],
      );
    }
    if (_isRecording) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, _) => Opacity(
              opacity: _pulseAnim.value,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF3B30), // iOS red — universally "recording"
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(l.voiceRecording,
              style: TextStyle(color: muted, fontSize: 13, letterSpacing: 2)),
        ],
      );
    }
    // Initialising
    return Text(l.voiceInitialising,
        style: TextStyle(color: muted, fontSize: 13, letterSpacing: 2));
  }

  Widget _buildCountdownRing(
      double progress, Color fg, Color muted, Color accent) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 3,
              color: muted.withValues(alpha: 0.15),
            ),
          ),
          // Progress arc
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, _) => Transform(
                // Rotate so the arc starts at the top (12 o'clock).
                alignment: Alignment.center,
                transform: Matrix4.rotationZ(-math.pi / 2),
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 3,
                  color: _remainingSeconds <= 15
                      ? const Color(0xFFFF3B30) // red when almost out of time
                      : accent,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
          ),
          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isTranscribing ? '…' : _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w200,
                  color: fg,
                  letterSpacing: -1,
                ),
              ),
              Text(
                _isTranscribing ? '' : '/ 2:00',
                style: TextStyle(
                  fontSize: 13,
                  color: fg.withValues(alpha: 0.35),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHint(AppLocalizations l, Color muted) {
    if (_isTranscribing) {
      return Text(
        l.voiceTranscribingHint,
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 14, height: 1.6),
      );
    }
    if (_isRecording) {
      return Text(
        l.voiceRecordingHint,
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, fontSize: 14, height: 1.6),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStopButton(
      AppLocalizations l, Color accent, ThemeData theme, double bottomInset) {
    if (_isTranscribing) {
      // Disabled while Whisper is working — just show a greyed-out button.
      return SizedBox(
        width: 200,
        height: 56,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
          ),
          child: Text(l.voiceTranscribing),
        ),
      );
    }

    return SizedBox(
      width: 200,
      height: 56,
      child: ElevatedButton(
        onPressed: _isRecording ? _stopAndTranscribe : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(
          l.diaryDone, // "完了" — already in l10n
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
