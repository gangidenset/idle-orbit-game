import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;

/// One facility's visual state.
class StructureData {
  const StructureData({
    required this.id,
    required this.tier,
    required this.color,
    this.evolvedAtMs,
  });

  final String id;

  /// 0 = not built, 1..6.
  final int tier;
  final Color color;
  final int? evolvedAtMs;
}

/// What the scene needs to know about the game. Pulled every frame so the
/// scene never holds stale state and never mutates the game.
class SceneData {
  const SceneData({
    required this.planetId,
    required this.planetColor,
    required this.structures,
    required this.decorations,
    required this.drones,
    required this.specialDrones,
    required this.boosted,
    required this.oreRate,
  });

  final String planetId;
  final Color planetColor;
  final List<StructureData> structures;
  final Set<String> decorations;
  final int drones;
  final int specialDrones;
  final bool boosted;
  final double oreRate;
}

/// Optional hand-made / AI-made art. Any file that exists replaces the
/// procedural drawing for that part; anything missing falls back.
///
/// ```text
///   assets/art/bg_{planetId}.png            background (portrait, ~1080x1080)
///   assets/art/planet_{planetId}.png        planet disc on transparency
///   assets/art/facility_{id}_t{tier}.png    building, base at bottom-centre
///   assets/art/deco_{decorationId}.png      decoration sprite
/// ```
class ArtLibrary {
  ArtLibrary._();

  /// Shared across scenes (main screen and the full-screen base view), so
  /// images are decoded once per app run.
  static final ArtLibrary instance = ArtLibrary._();

  final Map<String, Image> _images = {};
  Future<void>? _loading;

  Image? operator [](String name) => _images[name];

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final path in manifest.listAssets()) {
        if (!path.startsWith('assets/art/') || !path.endsWith('.png')) continue;
        final data = await rootBundle.load(path);
        final codec = await instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final name = path.substring('assets/art/'.length, path.length - 4);
        _images[name] = frame.image;
      }
    } catch (_) {
      // No art available: procedural drawing is used everywhere.
    }
  }
}

/// Paint for drawing art images: always opaque, smooth downscaling.
/// (A Paint's colour alpha multiplies drawImageRect, so shape paints whose
/// colour was last set semi-transparent must never be reused for images.)
final Paint _imagePaint = Paint()
  ..color = const Color(0xFFFFFFFF)
  ..filterQuality = FilterQuality.medium
  ..isAntiAlias = true;

/// The base on the current planet. Drawn with plain canvas calls (no
/// per-frame allocations beyond paints' state) to stay cheap on low-end
/// devices; the static starfield/nebula is rendered once per size.
class OrbitScene extends FlameGame {
  OrbitScene(
    this.data, {
    this.planetCenterY = 0.66,
    this.planetRadius = 0.27,
    this.idleSpin = false,
  });

  final SceneData Function() data;

  /// Planet centre as a fraction of the scene height.
  final double planetCenterY;

  /// Planet radius as a fraction of the scene's shorter side.
  final double planetRadius;

  /// Slowly turn the planet by itself when nobody is touching it.
  final bool idleSpin;

  /// Planet rotation around its vertical axis (radians). 0 = front view
  /// with the five facilities facing the viewer.
  double yaw = 0;
  double _yawVelocity = 0;
  double? _yawTarget;
  double _idle = 0;

  /// Turns the planet directly (finger drag).
  void spinBy(double radians) {
    yaw += radians;
    _yawVelocity = 0;
    _yawTarget = null;
    _idle = 0;
  }

  /// Lets go with a speed, so the planet keeps turning and slows down.
  void fling(double radiansPerSecond) {
    _yawVelocity = radiansPerSecond.clamp(-12.0, 12.0);
    _idle = 0;
  }

  /// Smoothly turns back to the front view (nearest full turn).
  void spinToFront() {
    const turn = math.pi * 2;
    _yawTarget = (yaw / turn).roundToDouble() * turn;
    _yawVelocity = 0;
    _idle = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final target = _yawTarget;
    if (target != null) {
      yaw += (target - yaw) * math.min(1.0, dt * 7);
      if ((target - yaw).abs() < 0.002) {
        yaw = target;
        _yawTarget = null;
      }
    } else if (_yawVelocity.abs() > 0.01) {
      yaw += _yawVelocity * dt;
      _yawVelocity *= math.exp(-2.2 * dt);
      _idle = 0;
    } else {
      _idle += dt;
      if (idleSpin && _idle > 4) yaw += 0.06 * dt;
    }
  }

  /// Where the planet is drawn for a scene of [size] (also used by the
  /// full-screen view to aim its close-up zoom).
  static (Offset, double) planetGeometry(Size size, {double centerY = 0.66, double radius = 0.27}) =>
      (Offset(size.width / 2, size.height * centerY), math.min(size.width, size.height) * radius);
  ArtLibrary get art => ArtLibrary.instance;

  @override
  Color backgroundColor() => const Color(0xFF050A1A);

  @override
  Future<void> onLoad() async {
    await art.load();
    add(_Backdrop());
    add(_Base());
  }
}

// ---------------------------------------------------------------- backdrop

class _Backdrop extends Component with HasGameReference<OrbitScene> {
  final _rng = math.Random(7);
  Picture? _static;
  Size _builtFor = Size.zero;
  String _builtPlanet = '';
  final List<(Offset, double, double)> _twinkle = [];
  double _t = 0;
  double _nextShoot = 3;
  Offset? _shootFrom;
  double _shootT = 0;
  final _p = Paint();

  void _build(Size size, SceneData d) {
    final rec = PictureRecorder();
    final c = Canvas(rec);
    final rect = Offset.zero & size;
    c.drawRect(
      rect,
      Paint()
        ..shader = Gradient.linear(rect.topCenter, rect.bottomCenter,
            [const Color(0xFF0A1433), const Color(0xFF04081A)]),
    );
    // Nebula: soft blobs tinted by the planet colour.
    final rng = math.Random(d.planetId.hashCode);
    for (var i = 0; i < 5; i++) {
      final center = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      final r = size.shortestSide * (0.35 + rng.nextDouble() * 0.4);
      final col = Color.lerp(d.planetColor, const Color(0xFF7C4DFF), rng.nextDouble() * 0.6)!;
      c.drawCircle(
        center,
        r,
        Paint()
          ..shader = Gradient.radial(center, r,
              [col.withValues(alpha: 0.16), col.withValues(alpha: 0)]),
      );
    }
    // Faint, static distant stars.
    final sp = Paint();
    for (var i = 0; i < 120; i++) {
      final a = 0.15 + rng.nextDouble() * 0.35;
      sp.color = const Color(0xFFFFFFFF).withValues(alpha: a);
      c.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 0.9 + 0.2, sp);
    }
    _static = rec.endRecording();
    _builtFor = size;
    _builtPlanet = d.planetId;
    _twinkle
      ..clear()
      ..addAll(List.generate(
          28,
          (_) => (
                Offset(_rng.nextDouble() * size.width, _rng.nextDouble() * size.height),
                _rng.nextDouble() * 1.2 + 0.6,
                _rng.nextDouble() * math.pi * 2,
              )));
  }

  @override
  void update(double dt) {
    _t += dt;
    _nextShoot -= dt;
    if (_shootFrom == null && _nextShoot <= 0) {
      final s = game.size;
      _shootFrom = Offset(_rng.nextDouble() * s.x * 0.8 + s.x * 0.2, _rng.nextDouble() * s.y * 0.3);
      _shootT = 0;
      _nextShoot = 5 + _rng.nextDouble() * 8;
    }
    if (_shootFrom != null) {
      _shootT += dt;
      if (_shootT > 0.8) _shootFrom = null;
    }
  }

  @override
  void render(Canvas canvas) {
    final d = game.data();
    final size = Size(game.size.x, game.size.y);
    final bg = game.art['bg_${d.planetId}'];
    if (bg != null) {
      _drawCover(canvas, bg, Offset.zero & size, _imagePaint);
    } else {
      if (_static == null || _builtFor != size || _builtPlanet != d.planetId) _build(size, d);
      canvas.drawPicture(_static!);
    }
    for (final (pos, r, phase) in _twinkle) {
      _p.color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 + 0.45 * math.sin(_t * 1.6 + phase).abs());
      canvas.drawCircle(pos, r, _p);
    }
    final from = _shootFrom;
    if (from != null) {
      final k = _shootT / 0.8;
      final head = from + Offset(-180 * k, 90 * k);
      _p
        ..shader = Gradient.linear(head, head + const Offset(40, -20),
            [const Color(0xFFFFFFFF).withValues(alpha: 1 - k), const Color(0x00FFFFFF)])
        ..strokeWidth = 1.6;
      canvas.drawLine(head, head + const Offset(40, -20), _p);
      _p.shader = null;
    }
  }
}

void _drawCover(Canvas c, Image img, Rect dst, Paint p) {
  final s = math.max(dst.width / img.width, dst.height / img.height);
  final w = dst.width / s, h = dst.height / s;
  final src = Rect.fromLTWH((img.width - w) / 2, (img.height - h) / 2, w, h);
  c.drawImageRect(img, src, dst, p);
}

// -------------------------------------------------------------------- base

class _Spark {
  _Spark(this.origin, this.dir, this.color);
  final Offset origin;
  final Offset dir;
  final Color color;
  double life = 1;
}

/// Where a surface object at a given longitude appears for the current
/// rotation. Objects live on a ring around the top of the planet: they slide
/// along the top rim as the planet turns and pass behind it on the far side.
class _RimSpot {
  const _RimSpot(this.angle, this.depth);

  /// Angle on the planet's rim (-pi/2 = top).
  final double angle;

  /// 1 = facing the viewer, -1 = directly behind the planet.
  final double depth;

  bool get front => depth >= 0;

  /// Far-side objects are drawn smaller.
  double get scale => 0.72 + 0.28 * (depth + 1) / 2;
}

class _Base extends Component with HasGameReference<OrbitScene> {
  double _t = 0;
  double _spawn = 0;
  final List<(double, double)> _puffs = []; // (rim angle, life)
  final List<_Spark> _sparks = [];
  final Map<String, int> _seenEvolution = {};
  final _fill = Paint();
  final _stroke = Paint()..style = PaintingStyle.stroke;
  final _rng = math.Random(11);

  /// How far along the rim the ring reaches on each side (radians).
  static const _ringSpread = 1.1;

  /// Rim angle between neighbouring facilities in the front view.
  static const _slotSpread = 0.30;

  /// Longitudes of the surface decorations on the far side of the planet.
  static const _decoLongitudes = {'comm_array': math.pi - 0.45, 'space_elevator': math.pi + 0.45};

  _RimSpot _spot(double longitude) {
    final a = longitude + game.yaw;
    return _RimSpot(-math.pi / 2 + _ringSpread * math.sin(a), math.cos(a));
  }

  /// Facilities are spaced so that, facing front, they sit where they did
  /// before the planet could turn (0.30 rad apart along the top rim).
  double _facilityLongitude(int i, int n) {
    final x = (i - (n - 1) / 2) * _slotSpread / _ringSpread;
    return math.asin(x.clamp(-1.0, 1.0));
  }

  @override
  void update(double dt) {
    _t += dt;
    final d = game.data();
    if (d.structures.isEmpty) return;
    // Mining dust rises from the ore mine (first facility) while it faces us.
    final mine = _spot(_facilityLongitude(0, d.structures.length));
    _spawn += dt * (0.5 + math.min(3.5, math.log(1 + d.oreRate)));
    while (_spawn > 1) {
      _spawn -= 1;
      if (mine.front) _puffs.add((mine.angle + (_rng.nextDouble() - 0.5) * 0.25, 1));
    }
    for (var i = 0; i < _puffs.length; i++) {
      _puffs[i] = (_puffs[i].$1, _puffs[i].$2 - dt * 0.8);
    }
    _puffs.removeWhere((p) => p.$2 <= 0);
    for (final s in _sparks) {
      s.life -= dt * 1.1;
    }
    _sparks.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    final d = game.data();
    final size = game.size;
    final (center, r) = OrbitScene.planetGeometry(Size(size.x, size.y),
        centerY: game.planetCenterY, radius: game.planetRadius);
    final now = DateTime.now().millisecondsSinceEpoch;
    final has = d.decorations.contains;

    Offset rimPoint(double angle) =>
        Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);

    // Everything standing on the surface, with where it currently appears.
    final items = <(_RimSpot, void Function(_RimSpot))>[];
    for (var i = 0; i < d.structures.length; i++) {
      final st = d.structures[i];
      final slot = i;
      items.add((
        _spot(_facilityLongitude(i, d.structures.length)),
        (spot) {
          final base = rimPoint(spot.angle);
          _structure(canvas, st, base, spot.angle, slot, spot.scale);
          final at = st.evolvedAtMs;
          if (at != null && _seenEvolution[st.id] != at) {
            _seenEvolution[st.id] = at;
            _burst(base, st.color);
          }
          if (at != null && now - at < 1200) _evolveFlash(canvas, base, st.color, (now - at) / 1200);
        },
      ));
    }
    if (has('comm_array')) {
      items.add((_spot(_decoLongitudes['comm_array']!), (spot) => _commArray(canvas, rimPoint(spot.angle), spot.angle, spot.scale)));
    }
    if (has('space_elevator')) {
      items.add((_spot(_decoLongitudes['space_elevator']!), (spot) => _elevator(canvas, center, r, spot.angle, spot.scale)));
    }
    // Far side first (the planet then hides their bases), nearest last.
    items.sort((a, b) => a.$1.depth.compareTo(b.$1.depth));

    if (has('warp_halo')) _warpHalo(canvas, center, r);
    if (has('moon')) _moon(canvas, center, r, front: false);
    _drones(canvas, d, center, r, front: false);
    if (has('station')) _station(canvas, center, r);
    // Far-side objects fade with depth so they read as behind the planet.
    for (final (spot, draw) in items) {
      if (spot.front) continue;
      final alpha = 0.45 + 0.55 * (1 + spot.depth);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha.clamp(0.45, 1.0)));
      draw(spot);
      canvas.restore();
    }

    _planet(canvas, d, center, r);
    if (has('city_lights')) _cityLights(canvas, center, r);
    if (has('aurora')) _aurora(canvas, center, r);

    for (final (spot, draw) in items) {
      if (spot.front) draw(spot);
    }

    for (final (angle, life) in _puffs) {
      final dist = r + 14 + (1 - life) * 36;
      final pos = Offset(center.dx + math.cos(angle) * dist, center.dy + math.sin(angle) * dist);
      _fill.color = const Color(0xFFD9B38C).withValues(alpha: life * 0.6);
      canvas.drawCircle(pos, 2 + (1 - life) * 3, _fill);
    }
    for (final s in _sparks) {
      final p = s.origin + s.dir * (1 - s.life) * 60;
      _fill.color = s.color.withValues(alpha: s.life);
      canvas.drawCircle(p, 2.2 * s.life + 0.5, _fill);
    }

    _drones(canvas, d, center, r, front: true);
    if (has('moon')) _moon(canvas, center, r, front: true);
  }

  // ---- planet

  void _planet(Canvas canvas, SceneData d, Offset c, double r) {
    final sprite = game.art['planet_${d.planetId}'];
    // Atmosphere glow.
    _fill.shader = Gradient.radial(c, r * 1.45, [
      d.planetColor.withValues(alpha: d.boosted ? 0.5 : 0.28),
      d.planetColor.withValues(alpha: 0),
    ]);
    canvas.drawCircle(c, r * 1.45, _fill);
    _fill.shader = null;

    // A seamless 2:1 surface texture turns with the planet; a disc image
    // cannot turn, so it is only used when no texture exists.
    final texture = game.art['planet_tex_${d.planetId}'];
    if (texture != null) {
      _texturedPlanet(canvas, texture, c, r);
      return;
    }
    if (sprite != null) {
      canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromCircle(center: c, radius: r), _imagePaint);
      return;
    }
    _fill.shader = Gradient.radial(
      c.translate(-r * 0.35, -r * 0.4),
      r * 1.5,
      [
        Color.lerp(d.planetColor, const Color(0xFFFFFFFF), 0.35)!,
        d.planetColor,
        Color.lerp(d.planetColor, const Color(0xFF000000), 0.7)!,
        const Color(0xFF02040C),
      ],
      [0, 0.35, 0.8, 1],
    );
    canvas.drawCircle(c, r, _fill);
    _fill.shader = null;

    // Surface bands, slowly drifting.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    _fill.color = const Color(0xFF000000).withValues(alpha: 0.10);
    for (var i = 0; i < 4; i++) {
      final y = c.dy - r * 0.6 + i * r * 0.38;
      final dx = math.sin(_t * 0.15 + i * 1.7) * r * 0.25;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(c.dx + dx, y), width: r * 1.9, height: r * 0.14), _fill);
    }
    // Surface patches at fixed longitudes: they slide across the face and
    // narrow towards the edge as the planet turns.
    final patch = math.Random(d.planetId.hashCode ^ 0x5f);
    for (var i = 0; i < 9; i++) {
      final lon = patch.nextDouble() * math.pi * 2;
      final lat = patch.nextDouble() * 1.4 - 0.7;
      final w = r * (0.25 + patch.nextDouble() * 0.35);
      final h = w * (0.35 + patch.nextDouble() * 0.3);
      final light = patch.nextBool();
      final a = lon + game.yaw;
      final facing = math.cos(a);
      if (facing <= 0) continue;
      final p = Offset(c.dx + math.cos(lat) * math.sin(a) * r, c.dy - math.sin(lat) * r);
      _fill.color = (light ? const Color(0xFFFFFFFF) : const Color(0xFF000000))
          .withValues(alpha: (light ? 0.10 : 0.14) * facing);
      canvas.drawOval(Rect.fromCenter(center: p, width: w * facing, height: h), _fill);
    }
    // Night side (lower right).
    _fill.shader = Gradient.radial(c.translate(r * 0.9, r * 0.7), r * 1.4,
        [const Color(0xFF000000).withValues(alpha: 0.55), const Color(0x00000000)]);
    canvas.drawCircle(c, r, _fill);
    _fill.shader = null;
    canvas.restore();

    // Rim light.
    _stroke
      ..strokeWidth = 1.5
      ..color = Color.lerp(d.planetColor, const Color(0xFFFFFFFF), 0.5)!.withValues(alpha: 0.5);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r - 0.5), math.pi * 0.95, math.pi * 0.8, false, _stroke);
  }

  void _texturedPlanet(Canvas canvas, Image tex, Offset c, double r) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final h = r * 2;
    final w = h * tex.width / tex.height; // one full turn = texture width
    var x = -((game.yaw / (math.pi * 2)) * w) % w;
    if (x > 0) x -= w;
    final src = Rect.fromLTWH(0, 0, tex.width.toDouble(), tex.height.toDouble());
    for (var dx = x; dx < r * 2; dx += w) {
      canvas.drawImageRect(tex, src, Rect.fromLTWH(c.dx - r + dx, c.dy - r, w, h), _imagePaint);
    }
    // Same lighting as the procedural planet so textures look round.
    _fill.shader = Gradient.radial(c.translate(-r * 0.35, -r * 0.4), r * 1.6, [
      const Color(0xFFFFFFFF).withValues(alpha: 0.18),
      const Color(0x00000000),
      const Color(0xFF000000).withValues(alpha: 0.6),
    ], [0, 0.45, 1]);
    canvas.drawCircle(c, r, _fill);
    _fill.shader = null;
    canvas.restore();
  }

  // ---- structures

  void _structure(Canvas canvas, StructureData s, Offset base, double angle, int slot, [double scale = 1]) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + math.pi / 2);
    if (scale != 1) canvas.scale(scale);

    final sprite = s.tier > 0 ? game.art['facility_${s.id}_t${s.tier}'] : null;
    if (sprite != null) {
      final h = 18.0 + s.tier * 7;
      final w = h * sprite.width / sprite.height;
      canvas.drawImageRect(sprite, Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromLTWH(-w / 2, -h + 2, w, h), _imagePaint);
      canvas.restore();
      return;
    }

    if (s.tier == 0) {
      // Empty plot.
      _stroke
        ..strokeWidth = 1
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.25);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -7, 12, 7), const Radius.circular(2)), _stroke);
      canvas.restore();
      return;
    }

    final t = s.tier;
    final col = s.color;
    final dark = Color.lerp(col, const Color(0xFF000000), 0.45)!;
    final blink = (math.sin(_t * 3 + slot) + 1) / 2;

    // Foundation grows wider with tier.
    final fw = 8.0 + t * 2.5;
    _fill.color = dark;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-fw, -3, fw * 2, 4), const Radius.circular(2)), _fill);

    // Main body.
    final bw = 5.0 + t * 1.6;
    final bh = 8.0 + t * 4.2;
    _fill.shader = Gradient.linear(Offset(-bw, 0), Offset(bw, 0), [Color.lerp(col, const Color(0xFFFFFFFF), 0.25)!, dark]);
    canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(-bw, -bh, bw * 2, bh),
        topLeft: Radius.circular(t >= 3 ? bw : 2), topRight: Radius.circular(t >= 3 ? bw : 2)), _fill);
    _fill.shader = null;

    // Side modules from tier 2.
    if (t >= 2) {
      _fill.color = Color.lerp(col, const Color(0xFF000000), 0.25)!;
      final mh = bh * 0.45;
      canvas.drawRect(Rect.fromLTWH(-bw - 5, -mh, 5, mh), _fill);
      canvas.drawRect(Rect.fromLTWH(bw, -mh * 0.8, 5, mh * 0.8), _fill);
    }
    // Lit windows.
    _fill.color = const Color(0xFFFFF3C4).withValues(alpha: 0.85);
    final rows = math.min(6, t + 1);
    for (var i = 0; i < rows; i++) {
      final y = -bh + 5 + i * (bh - 8) / math.max(1, rows);
      if ((i + slot) % 3 == 2 && t < 4) continue;
      canvas.drawRect(Rect.fromLTWH(-bw * 0.45, y, 2, 2), _fill);
      canvas.drawRect(Rect.fromLTWH(bw * 0.45 - 2, y, 2, 2), _fill);
    }
    // Antenna + beacon from tier 3.
    if (t >= 3) {
      _stroke
        ..strokeWidth = 1.2
        ..color = col;
      canvas.drawLine(Offset(0, -bh), Offset(0, -bh - 5 - t), _stroke);
      _fill.color = const Color(0xFFFF6B6B).withValues(alpha: 0.4 + 0.6 * blink);
      canvas.drawCircle(Offset(0, -bh - 6 - t), 2, _fill);
    }
    // Energy beam from tier 4.
    if (t >= 4) {
      final beamH = 18.0 + t * 5;
      _fill.shader = Gradient.linear(Offset(0, -bh), Offset(0, -bh - beamH),
          [col.withValues(alpha: 0.55 * (0.6 + 0.4 * blink)), col.withValues(alpha: 0)]);
      canvas.drawRect(Rect.fromLTWH(-1.5, -bh - beamH, 3, beamH), _fill);
      _fill.shader = null;
    }
    // Rotating rings from tier 5.
    if (t >= 5) {
      _stroke
        ..strokeWidth = 1.2
        ..color = col.withValues(alpha: 0.8);
      final ry = -bh * 0.6;
      final w = bw * 2.6 + math.sin(_t * 2 + slot) * 2;
      canvas.drawOval(Rect.fromCenter(center: Offset(0, ry), width: w, height: 5), _stroke);
    }
    // Radiant halo at the top tier.
    if (t >= 6) {
      final pulse = (math.sin(_t * 2.2 + slot) + 1) / 2;
      _fill.shader = Gradient.radial(Offset(0, -bh * 0.6), bh * (0.9 + 0.2 * pulse),
          [col.withValues(alpha: 0.35), col.withValues(alpha: 0)]);
      canvas.drawCircle(Offset(0, -bh * 0.6), bh * (0.9 + 0.2 * pulse), _fill);
      _fill.shader = null;
    }
    canvas.restore();
  }

  void _burst(Offset at, Color col) {
    for (var i = 0; i < 18; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 0.5 + _rng.nextDouble();
      _sparks.add(_Spark(at, Offset(math.cos(a) * sp, math.sin(a) * sp),
          i.isEven ? col : const Color(0xFFFFFFFF)));
    }
  }

  void _evolveFlash(Canvas canvas, Offset at, Color col, double k) {
    _stroke
      ..strokeWidth = 3 * (1 - k)
      ..color = col.withValues(alpha: 1 - k);
    canvas.drawCircle(at, 6 + k * 46, _stroke);
    _fill.shader = Gradient.radial(at, 30, [const Color(0xFFFFFFFF).withValues(alpha: (1 - k) * 0.8), const Color(0x00FFFFFF)]);
    canvas.drawCircle(at, 30, _fill);
    _fill.shader = null;
  }

  // ---- decorations

  void _moon(Canvas canvas, Offset c, double r, {required bool front}) {
    final a = _t * 0.18;
    final isFront = math.sin(a) > 0;
    if (isFront != front) return;
    final pos = Offset(c.dx + math.cos(a) * r * 1.9, c.dy + math.sin(a) * r * 0.55 - r * 0.15);
    final mr = r * 0.16 * (front ? 1.05 : 0.9);
    final sprite = game.art['deco_moon'];
    if (sprite != null) {
      canvas.drawImageRect(sprite, Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromCircle(center: pos, radius: mr), _imagePaint);
      return;
    }
    _fill.shader = Gradient.radial(pos.translate(-mr * 0.4, -mr * 0.4), mr * 1.6,
        [const Color(0xFFE8E4DA), const Color(0xFF8D877C), const Color(0xFF2A2824)], [0, 0.5, 1]);
    canvas.drawCircle(pos, mr, _fill);
    _fill.shader = null;
    _fill.color = const Color(0xFF000000).withValues(alpha: 0.15);
    canvas.drawCircle(pos.translate(mr * 0.2, -mr * 0.1), mr * 0.22, _fill);
    canvas.drawCircle(pos.translate(-mr * 0.35, mr * 0.3), mr * 0.14, _fill);
  }

  void _station(Canvas canvas, Offset c, double r) {
    final pos = Offset(c.dx - r * 1.25 + math.sin(_t * 0.3) * 6, c.dy - r * 1.25 + math.cos(_t * 0.4) * 4);
    final sprite = game.art['deco_station'];
    if (sprite != null) {
      canvas.drawImageRect(sprite, Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromCenter(center: pos, width: 44, height: 44), _imagePaint);
      return;
    }
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(_t * 0.2);
    _fill.color = const Color(0xFF4FC3F7).withValues(alpha: 0.85);
    canvas.drawRect(const Rect.fromLTWH(-20, -3, 12, 6), _fill); // panels
    canvas.drawRect(const Rect.fromLTWH(8, -3, 12, 6), _fill);
    _fill.color = const Color(0xFFCFD8DC);
    canvas.drawRect(const Rect.fromLTWH(-8, -1, 16, 2), _fill);
    canvas.drawCircle(Offset.zero, 5, _fill);
    _stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFFCFD8DC);
    canvas.drawCircle(Offset.zero, 9, _stroke);
    _fill.color = const Color(0xFFFFF3C4).withValues(alpha: 0.5 + 0.5 * ((math.sin(_t * 4) + 1) / 2));
    canvas.drawCircle(Offset.zero, 1.6, _fill);
    canvas.restore();
  }

  /// Lights sit at fixed longitudes/latitudes on the globe, so they travel
  /// with the planet's rotation; only those on the night side glow.
  void _cityLights(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r)));
    final rng = math.Random(5);
    for (var i = 0; i < 90; i++) {
      final lon = rng.nextDouble() * math.pi * 2;
      final lat = (rng.nextDouble() * 1.6 - 0.7); // mostly the lower half
      final size = 0.9 + rng.nextDouble() * 0.6;
      final a = lon + game.yaw;
      if (math.cos(a) < 0.05) continue; // far side
      final x = math.cos(lat) * math.sin(a);
      final y = -math.sin(lat);
      // Light comes from the top-left: only the bottom-right half is night.
      if (x * 0.6 + y * 0.8 < 0.15) continue;
      final p = Offset(c.dx + x * r, c.dy + y * r);
      final tw = 0.5 + 0.5 * math.sin(_t * 2 + i);
      _fill.color = const Color(0xFFFFD27A).withValues(alpha: 0.35 + 0.45 * tw);
      canvas.drawCircle(p, size, _fill);
    }
    canvas.restore();
  }

  void _aurora(Canvas canvas, Offset c, double r) {
    for (var band = 0; band < 2; band++) {
      final path = Path();
      for (var i = 0; i <= 24; i++) {
        final a = math.pi * 1.15 + i / 24 * math.pi * 0.7;
        final wave = math.sin(_t * 1.3 + i * 0.6 + band) * 4;
        final rr = r + 6 + band * 6 + wave;
        final p = Offset(c.dx + math.cos(a) * rr, c.dy + math.sin(a) * rr);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      _stroke
        ..strokeWidth = 5 - band * 2
        ..color = (band == 0 ? const Color(0xFF69F0AE) : const Color(0xFFB388FF)).withValues(alpha: 0.35);
      canvas.drawPath(path, _stroke);
    }
  }

  void _elevator(Canvas canvas, Offset c, double r, double angle, double scale) {
    final from = Offset(c.dx + math.cos(angle) * r, c.dy + math.sin(angle) * r);
    final len = r * 1.4 * scale;
    final to = from + Offset(math.cos(angle) * len, math.sin(angle) * len);
    _stroke
      ..strokeWidth = 1.4 * scale
      ..color = const Color(0xFFB0BEC5).withValues(alpha: 0.7);
    canvas.drawLine(from, to, _stroke);
    final k = (_t * 0.25) % 1;
    final car = Offset.lerp(from, to, k)!;
    _fill.color = const Color(0xFFFFD54F);
    canvas.drawCircle(car, 2.4 * scale, _fill);
    _fill.color = const Color(0xFFCFD8DC);
    canvas.drawCircle(to, 4 * scale, _fill);
  }

  void _warpHalo(Canvas canvas, Offset c, double r) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_t * 0.15);
    _stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFB388FF).withValues(alpha: 0.45);
    const dashes = 36;
    for (var i = 0; i < dashes; i += 2) {
      canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 1.65),
          i * math.pi * 2 / dashes, math.pi * 2 / dashes, false, _stroke);
    }
    canvas.restore();
  }

  void _commArray(Canvas canvas, Offset base, double angle, double scale) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + math.pi / 2);
    canvas.scale(scale);
    _stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFCFD8DC);
    canvas.drawLine(Offset.zero, const Offset(0, -10), _stroke);
    canvas.drawArc(const Rect.fromLTWH(-7, -18, 14, 10), 0, math.pi, false, _stroke);
    for (var i = 0; i < 3; i++) {
      final k = ((_t * 0.8 + i / 3) % 1);
      _stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF4FC3F7).withValues(alpha: (1 - k) * 0.7);
      canvas.drawArc(Rect.fromCenter(center: const Offset(0, -16), width: 10 + k * 26, height: 10 + k * 26),
          -math.pi * 0.85, math.pi * 0.7, false, _stroke);
    }
    canvas.restore();
  }

  void _drones(Canvas canvas, SceneData d, Offset c, double r, {required bool front}) {
    final total = d.drones + d.specialDrones;
    if (total == 0) return;
    final orbitR = r * 1.38;
    if (!front) {
      _stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.14);
      canvas.drawOval(Rect.fromCenter(center: c, width: orbitR * 2, height: orbitR * 0.7), _stroke);
    }
    for (var i = 0; i < total; i++) {
      final a = _t * (d.boosted ? 0.9 : 0.45) + i * (math.pi * 2 / total);
      final isFront = math.sin(a) > 0;
      if (isFront != front) continue;
      final pos = Offset(c.dx + math.cos(a) * orbitR, c.dy + math.sin(a) * orbitR * 0.35);
      final special = i < d.specialDrones;
      final size = (special ? 4.5 : 3.2) * (front ? 1 : 0.75);
      _fill.color = (special ? const Color(0xFFFFC857) : const Color(0xFF4FC3F7))
          .withValues(alpha: front ? 1 : 0.5);
      final dir = math.cos(a) < 0 ? 1.0 : -1.0; // facing travel direction
      final path = Path()
        ..moveTo(pos.dx + size * dir, pos.dy)
        ..lineTo(pos.dx - size * dir, pos.dy - size * 0.7)
        ..lineTo(pos.dx - size * dir, pos.dy + size * 0.7)
        ..close();
      canvas.drawPath(path, _fill);
    }
  }
}
