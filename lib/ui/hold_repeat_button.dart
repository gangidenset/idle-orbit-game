import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../game/game_controller.dart';
import '../services/audio/sound_service.dart';

/// An upgrade button that repeats while held.
///
/// * Tap: one step.
/// * Hold (≥ [holdDelay]): repeats, accelerating from [startInterval] to
///   [minInterval], until released or [onStep] reports it could not act.
///
/// [onStep] performs one step and returns whether it succeeded. Pass null to
/// disable the button. It is read fresh on every step, so the parent can
/// rebuild (e.g. with new costs) while the button is held.
class HoldRepeatButton extends StatefulWidget {
  const HoldRepeatButton({
    super.key,
    required this.onStep,
    required this.child,
    this.holdDelay = const Duration(milliseconds: 350),
    this.startInterval = const Duration(milliseconds: 200),
    this.minInterval = const Duration(milliseconds: 40),
  });

  final bool Function()? onStep;
  final Widget child;
  final Duration holdDelay;
  final Duration startInterval;
  final Duration minInterval;

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _timer;
  Timer? _badgeTimer;
  int _count = 0;
  bool _holding = false;
  int _lastFeedbackMs = 0;

  bool get _enabled => widget.onStep != null;

  @override
  void didUpdateWidget(HoldRepeatButton old) {
    super.didUpdateWidget(old);
    if (!_enabled && _holding) _stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _badgeTimer?.cancel();
    super.dispose();
  }

  /// Runs one step with throttled sound/haptics. Returns success.
  bool _step() {
    final step = widget.onStep;
    if (step == null || !step()) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFeedbackMs >= 70) {
      _lastFeedbackMs = now;
      context.read<SoundService>().play(Sfx.upgrade);
      if (context.read<GameController>().state.settings.haptics) {
        HapticFeedback.selectionClick();
      }
    }
    return true;
  }

  void _start() {
    if (!_enabled) return;
    setState(() {
      _holding = true;
      _count = 0;
    });
    _tick();
  }

  void _tick() {
    if (!mounted || !_holding) return;
    if (!_step()) {
      _stop();
      return;
    }
    setState(() => _count++);
    // Accelerate: each step ~18% faster, down to minInterval (25/sec).
    final ms = math.max(
      widget.minInterval.inMilliseconds,
      (widget.startInterval.inMilliseconds * math.pow(0.82, _count)).round(),
    );
    _timer = Timer(Duration(milliseconds: ms), _tick);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    setState(() => _holding = false);
    // Let the "+N" badge linger briefly so the result is visible.
    final shown = _count;
    _badgeTimer?.cancel();
    _badgeTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_holding && _count == shown) setState(() => _count = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: widget.holdDelay),
          (r) {
            r.onLongPressStart = (_) => _start();
            r.onLongPressEnd = (_) => _stop();
            r.onLongPressCancel = _stop;
          },
        ),
      },
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        AnimatedScale(
          scale: _holding ? 0.94 : 1,
          duration: const Duration(milliseconds: 90),
          child: FilledButton(
            onPressed: _enabled ? _step : null,
            child: widget.child,
          ),
        ),
        if (_count > 1)
          Positioned(
            top: -18,
            child: IgnorePointer(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 80),
                transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                child: Container(
                  key: ValueKey(_count),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: OrbitColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('+$_count',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
