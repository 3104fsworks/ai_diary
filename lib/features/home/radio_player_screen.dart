import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/models/radio_episode.dart';
import '../diary/widgets/particle_orb.dart';

/// Immersive radio playback screen — Gemini Live style.
///
/// Layout (full-screen dark):
///   Stack:
///     ① Background particle orb (full canvas)
///     ② Circular progress ring + audio waveform (center)
///     ③ Episode label + date (upper third)
///     ④ Bottom controls: ← ▮▮/▶ →  (prev / play-pause / next)
class RadioPlayerScreen extends StatefulWidget {
  final RadioEpisode episode;

  /// All available episodes sorted oldest→newest (for prev/next navigation).
  final List<RadioEpisode> allEpisodes;

  const RadioPlayerScreen({
    super.key,
    required this.episode,
    this.allEpisodes = const [],
  });

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen> {
  late RadioEpisode _current;

  final _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  @override
  void initState() {
    super.initState();
    _current = widget.episode;
    _subscribePlayer();
    _play(_current);
  }

  void _subscribePlayer() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playerState = s);
    });
    _posSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _durSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _total = d);
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ── Playback control ──────────────────────────────────────────────────

  Future<void> _play(RadioEpisode episode) async {
    final file = File(episode.audioFilePath);
    if (!await file.exists()) {
      _showSnack('音声ファイルが見つかりません');
      return;
    }
    await _player.stop();
    setState(() {
      _position = Duration.zero;
      _total = Duration.zero;
    });
    await _player.play(DeviceFileSource(episode.audioFilePath));
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else if (_playerState == PlayerState.paused) {
      await _player.resume();
    } else {
      await _play(_current);
    }
  }

  Future<void> _navigate(int delta) async {
    final all = _sortedEpisodes;
    if (all.isEmpty) return;
    final idx = all.indexWhere((e) => e.id == _current.id);
    final next = idx + delta;
    if (next < 0 || next >= all.length) return;
    setState(() {
      _current = all[next];
      _position = Duration.zero;
      _total = Duration.zero;
    });
    await _play(_current);
  }

  List<RadioEpisode> get _sortedEpisodes {
    if (widget.allEpisodes.isEmpty) return [widget.episode];
    final list = List<RadioEpisode>.from(widget.allEpisodes)
      ..sort((a, b) => a.generatedAt.compareTo(b.generatedAt));
    return list;
  }

  bool get _hasPrev {
    final all = _sortedEpisodes;
    final idx = all.indexWhere((e) => e.id == _current.id);
    return idx > 0;
  }

  bool get _hasNext {
    final all = _sortedEpisodes;
    final idx = all.indexWhere((e) => e.id == _current.id);
    return idx >= 0 && idx < all.length - 1;
  }

  void _showSnack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isPlaying = _playerState == PlayerState.playing;
    final progress = _total.inMilliseconds > 0
        ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final isMonthly = _current.isMonthly;
    final accentColor = isMonthly
        ? const Color(0xFFD4A853)
        : theme.colorScheme.primary;

    // Choose a very dark background
    final bgColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0A0A0A)
        : const Color(0xFF111111);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── ① Background particles ──────────────────────────────────
          Positioned.fill(
            child: ParticleOrb(
              size: size.width * 1.4,
              intensity: isPlaying ? 0.7 : 0.3,
              color: accentColor,
              particleCount: isMonthly ? 140 : 100,
            ),
          ),

          // ── ② Center: ring + waveform ───────────────────────────────
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular progress ring
                  AnimatedBuilder(
                    animation: const AlwaysStoppedAnimation(0),
                    builder: (_, _) => CustomPaint(
                      size: const Size(260, 260),
                      painter: _RingPainter(
                        progress: progress.toDouble(),
                        color: accentColor,
                        isMonthly: isMonthly,
                      ),
                    ),
                  ),
                  // Repaint when progress changes
                  _RingWidget(
                    progress: progress.toDouble(),
                    color: accentColor,
                    isMonthly: isMonthly,
                  ),
                  // Audio waveform
                  SizedBox(
                    width: 140,
                    height: 60,
                    child: _AudioWaveform(
                      isPlaying: isPlaying,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── ③ Episode info (upper area) ─────────────────────────────
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 30,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Episode type badge
                if (isMonthly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Text(
                      '✦ 月刊スペシャル ✦',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Text(
                    'AIラジオ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                const SizedBox(height: 6),
                // Date
                Text(
                  _episodeDateLabel(),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ── ④ Bottom controls ───────────────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress time
                    Text(
                      '${_fmt(_position)}  /  ${_total > Duration.zero ? _fmt(_total) : '--:--'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Controls row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ← Previous
                        _ControlButton(
                          icon: Icons.skip_previous_rounded,
                          size: 32,
                          enabled: _hasPrev,
                          onTap: () => _navigate(-1),
                        ),
                        const SizedBox(width: 32),

                        // ▶ / ▮▮ Play-pause (large)
                        GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentColor,
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.black,
                              size: 36,
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),

                        // → Next
                        _ControlButton(
                          icon: Icons.skip_next_rounded,
                          size: 32,
                          enabled: _hasNext,
                          onTap: () => _navigate(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _episodeDateLabel() {
    final d = _current.generatedAt;
    return '${d.year}年${d.month}月${d.day}日';
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular progress ring
// ─────────────────────────────────────────────────────────────────────────────

/// Separate StatefulWidget that rebuilds when progress changes.
class _RingWidget extends StatelessWidget {
  final double progress;
  final Color color;
  final bool isMonthly;

  const _RingWidget({
    required this.progress,
    required this.color,
    required this.isMonthly,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(260, 260),
      painter: _RingPainter(
        progress: progress,
        color: color,
        isMonthly: isMonthly,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;
  final bool isMonthly;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.isMonthly,
  });

  static const _strokeWidth = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - _strokeWidth;

    // Track
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // 12 o'clock
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }

    // Monthly: extra decorative outer ring
    if (isMonthly) {
      final outerPaint = Paint()
        ..color = color.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, radius + 10, outerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Audio waveform
// ─────────────────────────────────────────────────────────────────────────────

class _AudioWaveform extends StatefulWidget {
  final bool isPlaying;
  final Color color;
  static const _barCount = 18;

  const _AudioWaveform({
    required this.isPlaying,
    required this.color,
  });

  @override
  State<_AudioWaveform> createState() => _AudioWaveformState();
}

class _AudioWaveformState extends State<_AudioWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<double> _phases;
  late final List<double> _speeds;
  late final List<double> _amps;
  final _rand = math.Random(99);

  @override
  void initState() {
    super.initState();
    _phases = List.generate(
        _AudioWaveform._barCount, (_) => _rand.nextDouble() * math.pi * 2);
    _speeds = List.generate(
        _AudioWaveform._barCount, (_) => 1.2 + _rand.nextDouble() * 2.4);
    _amps = List.generate(
        _AudioWaveform._barCount, (_) => 0.3 + _rand.nextDouble() * 0.7);
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        painter: _WaveformPainter(
          t: _c.value,
          phases: _phases,
          speeds: _speeds,
          amps: _amps,
          barCount: _AudioWaveform._barCount,
          isPlaying: widget.isPlaying,
          color: widget.color,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double t;
  final List<double> phases;
  final List<double> speeds;
  final List<double> amps;
  final int barCount;
  final bool isPlaying;
  final Color color;

  const _WaveformPainter({
    required this.t,
    required this.phases,
    required this.speeds,
    required this.amps,
    required this.barCount,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width / barCount) * 0.55;
    final gap = size.width / barCount;
    final midY = size.height / 2;
    final maxHalf = size.height / 2 * 0.9;
    const minHalf = 3.0;

    final paint = Paint()
      ..color = color.withValues(alpha: isPlaying ? 0.85 : 0.3)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;

    for (int i = 0; i < barCount; i++) {
      final x = gap * i + gap / 2;
      double halfH;
      if (isPlaying) {
        final wave =
            math.sin(t * speeds[i] * math.pi * 2 + phases[i]);
        halfH = minHalf + (wave * 0.5 + 0.5) * (maxHalf - minHalf) * amps[i];
      } else {
        halfH = minHalf + (maxHalf - minHalf) * 0.15 * amps[i];
      }
      canvas.drawLine(
        Offset(x, midY - halfH),
        Offset(x, midY + halfH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.t != t || old.isPlaying != isPlaying;
}

// ─────────────────────────────────────────────────────────────────────────────
// Control button
// ─────────────────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool enabled;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Icon(
        icon,
        size: size,
        color: enabled
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }
}
