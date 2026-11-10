// ignore_for_file: avoid_print
// Early-game simulator: a greedy bot with active play only (no offline).
// Run: dart run tool/balance_sim.dart [hours]
// For multi-day play including offline rewards and warps see lifecycle_sim.dart.
import 'dart:io';

import 'package:idle_orbit/game/config/balance_config.dart';

import 'sim_bot.dart';

/// Simulates [hours] of play and returns seconds at which each planet unlocked.
Map<String, double> simulate(BalanceConfig config, {double hours = 12, bool verbose = false}) {
  final bot = SimBot(config);
  const t0 = 1700000000000;
  final s = bot.engine.newGame(t0);
  final unlockedAt = <String, double>{config.planets.first.id: 0};
  var t = 0.0;
  while (t < hours * 3600) {
    bot.engine.tick(s, 1, nowMs: t0 + (t * 1000).round());
    t += 1;
    if (t % 5 != 0) continue;
    final p = bot.tryUnlockPlanet(s);
    if (p != null) {
      unlockedAt[p] = t;
      if (verbose) print('${(t / 60).toStringAsFixed(1)} min: unlocked ${config.planet(p).name}');
      continue;
    }
    bot.spend(s);
  }
  if (verbose) {
    print('After ${hours}h: facilities=${s.facilities} robots=${s.robots}');
    print('warp points available: ${bot.prestige.pointsAvailable(s)}');
  }
  return unlockedAt;
}

void main(List<String> args) {
  final config =
      BalanceConfig.fromJsonString(File('assets/config/balance.json').readAsStringSync());
  simulate(config, hours: args.isEmpty ? 12.0 : double.parse(args.first), verbose: true);
}
