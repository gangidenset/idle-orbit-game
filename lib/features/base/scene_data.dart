import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../flame/orbit_scene.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';

/// Builds what the planet scene shows from the current game state.
/// Shared by the main screen and the full-screen base view.
SceneData buildSceneData(GameController c) {
  final s = c.state;
  final hired = c.config.robots.where((r) => s.robotLevel(r.id) > 0 && c.engine.isRobotUnlocked(s, r));
  final normal = hired.where((r) => !r.special);
  final special = hired.where((r) => r.special);
  final levels = normal.fold<int>(0, (a, r) => a + s.robotLevel(r.id));
  return SceneData(
    planetId: s.activePlanet,
    planetColor: Color(c.config.planet(s.activePlanet).colorValue),
    structures: [
      for (final f in c.config.facilities)
        StructureData(
          id: f.id,
          tier: c.visuals.tierFor(s.facilityLevel(f.id)),
          color: OrbitColors.facility(f.icon),
          evolvedAtMs: c.evolvedAtMs[f.id],
        ),
    ],
    decorations: {for (final d in c.visuals.activeDecorations(s)) d.id},
    // One drone per robot type plus one per 15 levels, capped for clarity.
    drones: math.min(12, normal.length + levels ~/ 15),
    specialDrones: special.length,
    boosted: c.engine.boostMultiplier(s, c.nowMs) > 1,
    oreRate: c.snap.gross[ResourceType.ore],
    monuments: [
      for (final (i, p) in c.visuals.monuments(s).indexed)
        MonumentData(
          planetId: p.id,
          color: Color(p.colorValue),
          latest: i == c.visuals.monuments(s).length - 1 && i > 0,
        ),
    ],
  );
}
