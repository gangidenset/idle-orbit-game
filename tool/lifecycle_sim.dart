// ignore_for_file: avoid_print
// Lifecycle simulator: a typical player over several weeks, including
// offline rewards and prestige (星系ワープ).
// Run: dart run tool/lifecycle_sim.dart [days] [--ads]
import 'dart:io';
import 'dart:math' as math;

import 'package:idle_orbit/game/config/balance_config.dart';
import 'package:idle_orbit/game/engine/offline_calculator.dart';
import 'package:idle_orbit/game/model/game_state.dart';

import 'sim_bot.dart';

class SimEvent {
  SimEvent(this.day, this.run, this.text, {this.planet, this.points});
  final double day;
  final int run;
  final String text;
  final String? planet;
  final int? points;
}

class LifecycleResult {
  LifecycleResult(this.events, this.state);
  final List<SimEvent> events;
  final GameState state;

  /// Day each planet was first unlocked (any run).
  Map<String, double> get firstUnlock {
    final m = <String, double>{};
    for (final e in events) {
      if (e.planet != null) m.putIfAbsent(e.planet!, () => e.day);
    }
    return m;
  }

  List<SimEvent> get warps => events.where((e) => e.points != null).toList();

  /// Day planet [id] was reached within run [run].
  double? reachedInRun(String id, int run) {
    for (final e in events) {
      if (e.run == run && e.planet == id) return e.day;
    }
    return null;
  }

  double runStartDay(int run) =>
      run == 1 ? 0 : warps[run - 2].day; // run N starts at warp N-1
}

/// Session start times (hours of day) and active minutes per session.
const sessionHours = [8.0, 12.5, 19.0, 22.5];
const sessionMinutes = 8.0;

LifecycleResult simulateLifecycle(BalanceConfig config,
    {int days = 30, bool adDouble = false}) {
  final bot = SimBot(config);
  final engine = bot.engine;
  final offline = OfflineCalculator(engine);
  const t0 = 1700000000000;
  final s = engine.newGame(t0);
  final events = <SimEvent>[];
  var run = 1;
  var runStartMs = t0;

  for (var day = 0; day < days; day++) {
    for (final h in sessionHours) {
      final startMs = t0 + ((day * 24 + h) * 3600 * 1000).round();
      // Offline reward for the time away.
      offline.computeAndStore(s, startMs);
      offline.claim(s, multiplier: adDouble ? config.offline.adMultiplier : 1);

      var t = 0.0;
      while (t < sessionMinutes * 60) {
        final now = startMs + (t * 1000).round();
        engine.tick(s, 1, nowMs: now);
        t += 1;
        if (t % 5 != 0) continue;
        final p = bot.tryUnlockPlanet(s);
        if (p != null) {
          events.add(SimEvent(_day(now, t0), run, 'unlock ${config.planet(p).name}', planet: p));
          continue;
        }
        bot.spend(s);
      }
      final endMs = startMs + (sessionMinutes * 60 * 1000).round();
      s.lastSeenMs = endMs;
      s.highWaterMs = endMs;

      // Typical player warp rule: warp when the pending points are a solid
      // gain (+50% of everything earned so far), or accept a smaller gain
      // once the run has gone on for more than a day.
      final pts = bot.prestige.pointsAvailable(s);
      final earned = s.stat(Metric.prestigePointsEarned);
      final runDays = (endMs - runStartMs) / 86400000;
      if (bot.prestige.canPrestige(s) &&
          (pts >= math.max(3, earned * 0.5) || (runDays >= 1 && pts >= earned * 0.2))) {
        final got = bot.prestige.prestige(s, endMs);
        events.add(SimEvent(_day(endMs, t0), run, 'WARP +$got pt (run ${runDays.toStringAsFixed(1)}d)',
            points: got));
        bot.spendPrestige(s);
        run++;
        runStartMs = endMs;
      }
    }
  }
  return LifecycleResult(events, s);
}

double _day(int ms, int t0) => (ms - t0) / 86400000;

void main(List<String> args) {
  final cfgArg = args.where((a) => a.startsWith('--config=')).firstOrNull;
  final path = cfgArg?.substring(9) ?? 'assets/config/balance.json';
  final config = BalanceConfig.fromJsonString(File(path).readAsStringSync());
  final days = args.isNotEmpty && !args.first.startsWith('--') ? int.parse(args.first) : 30;
  final r = simulateLifecycle(config, days: days, adDouble: args.contains('--ads'));
  for (final e in r.events) {
    print('day ${e.day.toStringAsFixed(2).padLeft(6)}  run ${e.run.toString().padLeft(2)}  ${e.text}');
  }
  print('\nfirst unlock (day): ${r.firstUnlock.map((k, v) => MapEntry(k, v.toStringAsFixed(2)))}');
  print('warps: ${r.warps.length}, prestige upgrades: ${r.state.prestigeUpgrades}, '
      'unspent pts: ${r.state.prestigePoints}');
}
