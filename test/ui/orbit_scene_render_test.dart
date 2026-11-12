import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/logger.dart';
import 'package:idle_orbit/flame/orbit_scene.dart';

/// Actually renders the Flame scene (with every tier, decoration and
/// monument) all the way around the planet, and fails on any drawing error.
/// Widget tests don't run Flame's own loop, so it is driven by hand.
void main() {
  testWidgets('scene draws without errors at every rotation', (tester) async {
    final errors = <String>[];
    log.onError = (e, _, msg) => errors.add('$msg: $e');
    addTearDown(() => log.onError = null);

    const colors = [Color(0xFFD9B38C), Color(0xFFFFD54F), Color(0xFF80DEEA), Color(0xFFCE93D8), Color(0xFF90A4AE)];
    final scene = OrbitScene(
      () => SceneData(
        planetId: 'terra_nova',
        planetColor: const Color(0xFF4FA3E0),
        structures: [
          for (var i = 0; i < 5; i++)
            StructureData(
              id: 'f$i',
              tier: [0, 1, 3, 5, 6][i],
              color: colors[i],
              // One building mid-evolution, to draw the flash and sparks.
              evolvedAtMs: i == 2 ? DateTime.now().millisecondsSinceEpoch : null,
            ),
        ],
        decorations: const {
          'city_lights', 'comm_array', 'moon', 'station', 'space_elevator', 'warp_halo', 'aurora',
        },
        drones: 6,
        specialDrones: 2,
        boosted: true,
        oreRate: 1000,
        monuments: [
          for (var i = 0; i < 5; i++)
            MonumentData(planetId: 'p$i', color: colors[i], latest: i == 4),
        ],
      ),
      planetCenterY: 0.6,
      planetRadius: 0.36,
      idleSpin: true,
    );

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(width: 390, height: 600, child: GameWidget(game: scene)),
    ));
    // Let onLoad (asset manifest) finish: it needs real async I/O and frames.
    for (var i = 0; i < 40 && !scene.isLoaded; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(scene.isLoaded, isTrue);

    for (var k = 0; k <= 20; k++) {
      scene.yaw = k / 20 * 2 * math.pi;
      scene.update(1 / 60);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'yaw step $k');
    }
    expect(errors, isEmpty);

    // The planet must stay solid at every angle. (Shared paints left
    // translucent by the previous object once made it see-through, at some
    // angles only.) Render to an image and compare the planet's centre.
    final brightness = <double>[];
    for (var k = 0; k < 12; k++) {
      scene.yaw = k / 12 * 2 * math.pi;
      final recorder = ui.PictureRecorder();
      scene.render(Canvas(recorder));
      final picture = recorder.endRecording();
      final value = await tester.runAsync(() async {
        final image = await picture.toImage(390, 600);
        final data = await image.toByteData();
        // Planet centre: x = 0.5 w, y = 0.6 h; sample a little below it.
        final i = ((380 * 390) + 195) * 4;
        return (data!.getUint8(i) + data.getUint8(i + 1) + data.getUint8(i + 2)) / 3;
      });
      brightness.add(value!);
    }
    final lo = brightness.reduce(math.min), hi = brightness.reduce(math.max);
    expect(lo / hi, greaterThan(0.8), reason: 'planet brightness by angle: $brightness');
  });
}
