import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';

/// What the scene needs to know about the game. Pulled every frame so the
/// scene never holds stale state and never mutates the game.
class SceneData {
  const SceneData({
    required this.planetColor,
    required this.facilityLevels,
    required this.robotCount,
    required this.boosted,
    required this.oreRate,
    required this.premium,
  });

  final Color planetColor;

  /// Ordered levels for the five facilities (0 = not built).
  final List<int> facilityLevels;
  final int robotCount;
  final bool boosted;
  final double oreRate;
  final bool premium;
}

/// Lightweight 2D scene: a starfield, the current planet, base structures on
/// its surface and orbiting robot drones. Everything is drawn in a single
/// component with plain canvas calls to stay cheap on low-end devices.
class OrbitScene extends FlameGame {
  OrbitScene(this.data);

  final SceneData Function() data;

  @override
  Color backgroundColor() => const Color(0xFF070E22);

  @override
  Future<void> onLoad() async {
    add(_StarField());
    add(_PlanetBase(data));
  }
}

class _Star {
  _Star(this.pos, this.radius, this.phase);
  final Vector2 pos;
  final double radius;
  final double phase;
}

class _StarField extends Component with HasGameReference<OrbitScene> {
  final _rng = math.Random(7);
  final List<_Star> _stars = [];
  double _t = 0;
  final _paint = Paint();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _stars
      ..clear()
      ..addAll(List.generate(
        70,
        (_) => _Star(
          Vector2(_rng.nextDouble() * size.x, _rng.nextDouble() * size.y),
          _rng.nextDouble() * 1.3 + 0.3,
          _rng.nextDouble() * math.pi * 2,
        ),
      ));
  }

  @override
  void update(double dt) => _t += dt;

  @override
  void render(Canvas canvas) {
    for (final s in _stars) {
      final a = 0.35 + 0.35 * math.sin(_t * 1.5 + s.phase);
      _paint.color = const Color(0xFFFFFFFF).withValues(alpha: a);
      canvas.drawCircle(s.pos.toOffset(), s.radius, _paint);
    }
  }
}

class _Puff {
  _Puff(this.angle, this.life);
  final double angle;
  double life;
}

class _PlanetBase extends Component with HasGameReference<OrbitScene> {
  _PlanetBase(this.data);

  final SceneData Function() data;
  double _t = 0;
  double _spawn = 0;
  final List<_Puff> _puffs = [];
  final _fill = Paint();
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  static const _structureColors = [
    Color(0xFFB8A48C), // ore mine
    Color(0xFFFFD54F), // power
    Color(0xFF80DEEA), // alloy
    Color(0xFFCE93D8), // research
    Color(0xFF90A4AE), // storage
  ];

  @override
  void update(double dt) {
    _t += dt;
    final d = data();
    // Mining puffs rise from the ore mine; frequency follows production.
    _spawn += dt * (0.6 + math.min(4.0, math.log(1 + d.oreRate)));
    while (_spawn > 1) {
      _spawn -= 1;
      _puffs.add(_Puff(-math.pi / 2 + (math.Random().nextDouble() - 0.5) * 0.5, 1));
    }
    for (final p in _puffs) {
      p.life -= dt * 0.8;
    }
    _puffs.removeWhere((p) => p.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    final d = data();
    final size = game.size;
    final center = Offset(size.x / 2, size.y * 0.58);
    final r = math.min(size.x, size.y) * 0.30;
    final rot = _t * 0.05;

    // Atmosphere glow.
    _fill
      ..shader = Gradient.radial(center, r * 1.5, [
        d.planetColor.withValues(alpha: d.boosted ? 0.45 : 0.25),
        d.planetColor.withValues(alpha: 0),
      ])
      ..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(center, r * 1.5, _fill);

    // Planet body with simple lighting.
    _fill.shader = Gradient.radial(
      center.translate(-r * 0.35, -r * 0.35),
      r * 1.4,
      [
        Color.lerp(d.planetColor, const Color(0xFFFFFFFF), 0.25)!,
        d.planetColor,
        Color.lerp(d.planetColor, const Color(0xFF000000), 0.75)!,
      ],
      [0, 0.45, 1],
    );
    canvas.drawCircle(center, r, _fill);
    _fill.shader = null;

    // Surface bands (rotating) for a sense of motion.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));
    _fill.color = const Color(0xFF000000).withValues(alpha: 0.12);
    for (var i = 0; i < 3; i++) {
      final y = center.dy - r * 0.5 + i * r * 0.45;
      final dx = math.sin(rot * 4 + i) * r * 0.2;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx + dx, y), width: r * 1.8, height: r * 0.18),
          _fill);
    }
    canvas.restore();

    // Base structures along the top arc of the planet.
    for (var i = 0; i < d.facilityLevels.length; i++) {
      final lvl = d.facilityLevels[i];
      final angle = -math.pi / 2 + (i - 2) * 0.32;
      final base = Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle + math.pi / 2);
      if (lvl <= 0) {
        _stroke.color = const Color(0xFFFFFFFF).withValues(alpha: 0.25);
        canvas.drawRect(const Rect.fromLTWH(-5, -8, 10, 8), _stroke);
      } else {
        final double h = 8 + math.min(22.0, math.sqrt(lvl.toDouble()) * 3);
        _fill.color = _structureColors[i];
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(-6, -h, 12, h), const Radius.circular(2)),
            _fill);
        // Blinking beacon.
        final blink = (math.sin(_t * 3 + i) + 1) / 2;
        _fill.color = const Color(0xFFFFFFFF).withValues(alpha: 0.4 + 0.6 * blink);
        canvas.drawCircle(Offset(0, -h - 3), 2, _fill);
      }
      canvas.restore();
    }

    // Mining puffs.
    for (final p in _puffs) {
      final dist = r + 10 + (1 - p.life) * 40;
      final pos = Offset(center.dx + math.cos(p.angle) * dist - r * 0.3,
          center.dy + math.sin(p.angle) * dist);
      _fill.color = const Color(0xFFB8A48C).withValues(alpha: p.life * 0.7);
      canvas.drawCircle(pos, 2 + (1 - p.life) * 3, _fill);
    }

    // Orbit ring and robot drones.
    final orbitR = r * 1.35;
    _stroke.color = const Color(0xFF4FC3F7).withValues(alpha: 0.18);
    canvas.drawOval(
        Rect.fromCenter(center: center, width: orbitR * 2, height: orbitR * 0.7), _stroke);
    final drones = math.min(12, d.robotCount);
    for (var i = 0; i < drones; i++) {
      final a = _t * (d.boosted ? 0.9 : 0.45) + i * (math.pi * 2 / drones);
      final pos = Offset(center.dx + math.cos(a) * orbitR, center.dy + math.sin(a) * orbitR * 0.35);
      final front = math.sin(a) > 0;
      _fill.color = (d.premium ? const Color(0xFFB2FF59) : const Color(0xFF4FC3F7))
          .withValues(alpha: front ? 1 : 0.45);
      canvas.drawCircle(pos, front ? 3.5 : 2.5, _fill);
    }
  }
}
