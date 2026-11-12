import 'dart:math' as math;

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
  });
}
