// ignore_for_file: avoid_print
// Balance simulator: a greedy bot plays the game with active play only.
// Run: dart run tool/balance_sim.dart [hours]
import 'dart:io';

import 'package:idle_orbit/game/config/balance_config.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/prestige_system.dart';
import 'package:idle_orbit/game/model/resources.dart';

/// Simulates [hours] of play and returns seconds at which each planet unlocked.
Map<String, double> simulate(BalanceConfig config, {double hours = 12, bool verbose = false}) {
  final engine = GameEngine(config);
  final prestige = PrestigeSystem(engine);
  const t0 = 1700000000000;
  final s = engine.newGame(t0);
  final unlockedAt = <String, double>{config.planets.first.id: 0};
  const dt = 1.0;
  var t = 0.0;

  double weight(ResourceBag c) =>
      c[ResourceType.ore] +
      c[ResourceType.energy] * 2 +
      c[ResourceType.alloy] * 20 +
      c[ResourceType.research] * 100;

  while (t < hours * 3600) {
    final now = t0 + (t * 1000).round();
    engine.tick(s, dt, nowMs: now);
    t += dt;
    if (t % 5 != 0) continue;

    final next = engine.nextLockedPlanet(s);
    if (next != null && engine.unlockPlanet(s, next.id)) {
      unlockedAt[next.id] = t;
      if (verbose) print('${(t / 60).toStringAsFixed(1)} min: unlocked ${next.name}');
      continue;
    }
    for (final r in config.research) {
      engine.doResearch(s, r.id);
    }
    // Buy the cheapest available upgrade repeatedly.
    for (var i = 0; i < 50; i++) {
      String? best;
      var bestCost = double.infinity;
      void consider(String key, ResourceBag cost, bool ok) {
        if (!ok) return;
        final w = weight(cost);
        if (w < bestCost) {
          bestCost = w;
          best = key;
        }
      }

      for (final f in config.facilities) {
        // Save for the planet: don't spend alloy/research meant for it.
        consider('f:${f.id}', engine.facilityCost(s, f.id),
            engine.facilityBlock(s, f.id) == UpgradeBlock.none);
      }
      for (final r in config.robots) {
        consider('r:${r.id}', engine.robotCost(s, r.id),
            engine.robotBlock(s, r.id) == UpgradeBlock.none);
      }
      final b = best;
      if (b == null) break;
      if (b.startsWith('f:')) {
        engine.upgradeFacility(s, b.substring(2));
      } else {
        engine.upgradeRobot(s, b.substring(2));
      }
    }
  }
  if (verbose) {
    print('After ${hours}h: facilities=${s.facilities} robots=${s.robots}');
    print('research=${s.research}');
    print('resources=${s.resources}');
    print('prestige points available: ${prestige.pointsAvailable(s)}');
    print('player level: ${engine.playerLevel(s)}');
  }
  return unlockedAt;
}

void main(List<String> args) {
  final config =
      BalanceConfig.fromJsonString(File('assets/config/balance.json').readAsStringSync());
  final hours = args.isEmpty ? 12.0 : double.parse(args.first);
  simulate(config, hours: hours, verbose: true);
}

