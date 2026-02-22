import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/spacey_bottom_nav.dart';

const _keyMissionId = 'focus_mission_id';
const _keyStartTs = 'focus_start_ts';
const _keyDuration = 'focus_duration_seconds';

class FocusTimerScreen extends ConsumerStatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;
  Timer? _timer;
  int _totalSeconds = 25 * 60;
  int _remaining = 25 * 60;
  bool _running = false;
  bool _complete = false;
  String? _activeMissionId;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadPersistedState();
  }

  Future<void> _loadPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    final startTs = prefs.getInt(_keyStartTs);
    final duration = prefs.getInt(_keyDuration);
    if (startTs != null && duration != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch ~/ 1000 - startTs;
      final remaining = duration - elapsed;
      if (remaining > 0) {
        setState(() {
          _totalSeconds = duration;
          _remaining = remaining;
          _activeMissionId = prefs.getString(_keyMissionId);
        });
        _startTimer();
      } else {
        await _clearPersistedState();
      }
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyStartTs,
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    await prefs.setInt(_keyDuration, _totalSeconds);
    if (_activeMissionId != null)
      prefs.setString(_keyMissionId, _activeMissionId!);
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTs);
    await prefs.remove(_keyDuration);
    await prefs.remove(_keyMissionId);
  }

  void _startTimer() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining <= 0) {
        t.cancel();
        _onComplete();
        return;
      }
      setState(() => _remaining--);
    });
    _persistState();
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  Future<void> _onComplete() async {
    HapticFeedback.heavyImpact();
    await _clearPersistedState();
    setState(() {
      _running = false;
      _complete = true;
    });
    // Log to Supabase
    try {
      await Supabase.instance.client.from('focus_sessions').insert({
        'user_id': Supabase.instance.client.auth.currentUser!.id,
        'mission_id': _activeMissionId,
        'started_at': DateTime.now()
            .subtract(Duration(seconds: _totalSeconds))
            .toIso8601String(),
        'ended_at': DateTime.now().toIso8601String(),
        'duration_seconds': _totalSeconds,
      });
    } catch (_) {} // Non-critical
  }

  void _setPreset(int minutes) {
    _timer?.cancel();
    setState(() {
      _totalSeconds = minutes * 60;
      _remaining = minutes * 60;
      _running = false;
      _complete = false;
    });
  }

  void _reset() {
    _timer?.cancel();
    _clearPersistedState();
    setState(() {
      _remaining = _totalSeconds;
      _running = false;
      _complete = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Starfield
          AnimatedBuilder(
            animation: _starController,
            builder: (_, __) => CustomPaint(
              painter: _StarfieldPainter(_starController.value),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: _complete ? _buildCompleteState() : _buildTimerState(),
          ),
        ],
      ),
      bottomNavigationBar: const SpaceyBottomNav(currentIndex: 1),
    );
  }

  Widget _buildTimerState() {
    final progress = _remaining / _totalSeconds;
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.text),
                onPressed: () => context.go('/'),
              ),
              const Expanded(
                child: Text(
                  'Deep Space Mode',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        // Preset buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final m in [25, 45, 90])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: OutlinedButton(
                  onPressed: () => _setPreset(m),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _totalSeconds == m * 60
                        ? AppTheme.primary
                        : Colors.grey,
                    side: BorderSide(
                      color: _totalSeconds == m * 60
                          ? AppTheme.primary
                          : Colors.grey,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: Text('${m}m', style: const TextStyle(fontSize: 13)),
                ),
              ),
          ],
        ),
        const Spacer(),
        // Circular Timer
        SizedBox(
          width: 260,
          height: 260,
          child: CustomPaint(
            painter: _TimerRingPainter(progress),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      letterSpacing: 4,
                    ),
                  ),
                  if (_activeMissionId != null)
                    const Text(
                      'Mission Active',
                      style: TextStyle(color: AppTheme.accent, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey, size: 32),
              onPressed: _reset,
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: _running ? _pauseTimer : _startTimer,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildCompleteState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 100,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 24),
          const Text(
            'Mission Complete!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Outstanding work, Commander.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _reset,
            child: const Text('Start New Mission'),
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  _TimerRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Progress arc (glow)
    final glowPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progress * 2 * pi,
      false,
      glowPaint,
    );

    // Main arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progress * 2 * pi,
      false,
      Paint()
        ..color = AppTheme.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) => old.progress != progress;
}

class _StarfieldPainter extends CustomPainter {
  final double t;
  static final _rand = Random(42);
  static final _stars = List.generate(
    120,
    (_) => Offset(_rand.nextDouble(), _rand.nextDouble()),
  );
  static final _sizes = List.generate(
    120,
    (_) => _rand.nextDouble() * 2.5 + 0.5,
  );

  _StarfieldPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.background,
    );

    final paint = Paint()..color = Colors.white;
    for (int i = 0; i < _stars.length; i++) {
      final twinkle = (sin(t * 2 * pi * (i % 7 + 1)) * 0.5 + 0.5);
      paint.color = Colors.white.withValues(alpha: 0.3 + 0.7 * twinkle);
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter old) => old.t != t;
}
