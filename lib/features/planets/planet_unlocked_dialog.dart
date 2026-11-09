import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/config/balance_config.dart';
import '../../services/audio/sound_service.dart';
import '../../ui/widgets.dart';

/// Celebration shown when a new planet is unlocked.
Future<void> showPlanetUnlocked(BuildContext context, PlanetConfig planet) {
  playSfx(context, Sfx.unlock);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (ctx, _, _) => _PlanetUnlocked(planet: planet),
  );
}

class _PlanetUnlocked extends StatefulWidget {
  const _PlanetUnlocked({required this.planet});
  final PlanetConfig planet;

  @override
  State<_PlanetUnlocked> createState() => _PlanetUnlockedState();
}

class _PlanetUnlockedState extends State<_PlanetUnlocked> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.planet.colorValue);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            final t = _ctrl.value;
            final pop = Curves.elasticOut.transform((t / 0.6).clamp(0.0, 1.0));
            final fade = (t / 0.3).clamp(0.0, 1.0);
            return Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _BurstPainter(t, color))),
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Opacity(
                    opacity: fade,
                    child: const Text('新惑星 開拓成功！',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: OrbitColors.accent)),
                  ),
                  const SizedBox(height: 24),
                  Transform.scale(
                    scale: 0.2 + 0.8 * pop,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.4, -0.4),
                          colors: [Colors.white, color, Colors.black],
                          stops: const [0, 0.45, 1],
                        ),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 48)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: fade,
                    child: Column(children: [
                      Text(widget.planet.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(widget.planet.description, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 8),
                      Text('全資源の生産 ×${fmt(widget.planet.permanentMultiplier)}',
                          style: const TextStyle(
                              fontSize: 18, color: OrbitColors.success, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(height: 32),
                  AnimatedOpacity(
                    opacity: t > 0.5 ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: FilledButton(
                      onPressed: t > 0.5 ? () => Navigator.pop(context) : null,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text('着陸する'),
                      ),
                    ),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color);
  final double t;
  final Color color;
  static final _rng = math.Random(3);
  static final _particles = List.generate(
      48, (_) => (_rng.nextDouble() * math.pi * 2, 0.5 + _rng.nextDouble(), _rng.nextInt(3)));

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final p = Paint();
    final colors = [color, OrbitColors.accent, Colors.white];
    final e = Curves.easeOut.transform(t);
    for (final (angle, speed, ci) in _particles) {
      final d = e * speed * size.shortestSide * 0.55;
      p.color = colors[ci].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.drawCircle(c + Offset(math.cos(angle) * d, math.sin(angle) * d), 3, p);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
