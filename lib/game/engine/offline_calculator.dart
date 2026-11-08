import 'dart:math' as math;

import '../model/game_state.dart';
import '../model/resources.dart';
import 'game_engine.dart';

/// Computes rewards for time spent away from the game. Runs fully on-device.
///
/// Anti-tamper strategy (no server):
/// * Elapsed time is measured from `highWaterMs`, the largest wall clock
///   value ever observed, not from the last save. Rolling the clock back and
///   forward again therefore never yields extra time.
/// * If the clock is behind `highWaterMs` (beyond a small tolerance), no
///   reward is granted and the player is told why.
/// * The reward is capped (8h by default), which bounds the gain from setting
///   the clock forward to a single cap's worth, after which real time must
///   catch up before anything is granted again.
class OfflineCalculator {
  OfflineCalculator(this.engine);

  final GameEngine engine;

  /// Small backward drift (NTP sync etc.) is tolerated.
  static const rollbackToleranceMs = 2 * 60 * 1000;

  /// Computes the pending reward for returning at [nowMs] and stores it on
  /// the state. Returns the reward, or null when nothing needs showing.
  OfflineReward? computeAndStore(GameState s, int nowMs) {
    final from = s.highWaterMs;
    if (nowMs < from - rollbackToleranceMs) {
      // Clock moved backwards. Grant nothing; keep high water so the rolled
      // back period cannot be harvested later.
      s.lastSeenMs = nowMs;
      final r = OfflineReward(
        elapsedSeconds: 0,
        creditedSeconds: 0,
        gained: ResourceBag(),
        capped: false,
        clockAnomaly: true,
      );
      s.pendingOfflineReward = _merge(s.pendingOfflineReward, r);
      return s.pendingOfflineReward;
    }

    final elapsed = math.max(0, (nowMs - from) ~/ 1000);
    s.lastSeenMs = nowMs;
    s.highWaterMs = math.max(s.highWaterMs, nowMs);
    if (elapsed < engine.config.offline.minSecondsForReward) {
      return s.pendingOfflineReward;
    }

    final r = simulate(s, from, elapsed);
    s.pendingOfflineReward = _merge(s.pendingOfflineReward, r);
    return s.pendingOfflineReward;
  }

  /// Simulates [elapsedSeconds] of offline production starting at [fromMs]
  /// without mutating [s].
  OfflineReward simulate(GameState s, int fromMs, int elapsedSeconds) {
    final mods = engine.modifiers(s);
    final capSeconds = (mods.offlineCapHours * 3600).round();
    final credited = math.min(elapsedSeconds, capSeconds);
    final eff = mods.offlineEfficiency.clamp(0.0, 10.0);

    final sim = GameState.fromJson(s.toJson());
    final before = sim.resources.copy();
    final step = engine.config.offline.simStepSeconds;
    var t = 0.0;
    while (t < credited) {
      final dt = math.min(step, credited - t);
      final now = fromMs + (t * 1000).round();
      // Efficiency scales the effective time, so consumption and production
      // stay balanced. Boost expiry is respected per step.
      engine.tick(sim, dt * eff, nowMs: now, active: false, mods: mods);
      t += dt;
    }
    final gained = ResourceBag();
    for (final r in ResourceType.values) {
      gained[r] = math.max(0.0, sim.resources[r] - before[r]);
    }
    return OfflineReward(
      elapsedSeconds: elapsedSeconds,
      creditedSeconds: credited,
      gained: gained,
      capped: elapsedSeconds > capSeconds,
      clockAnomaly: false,
    );
  }

  OfflineReward _merge(OfflineReward? a, OfflineReward b) {
    if (a == null) return b;
    return OfflineReward(
      elapsedSeconds: a.elapsedSeconds + b.elapsedSeconds,
      creditedSeconds: a.creditedSeconds + b.creditedSeconds,
      gained: a.gained + b.gained,
      capped: a.capped || b.capped,
      clockAnomaly: a.clockAnomaly || b.clockAnomaly,
    );
  }

  /// Claims the pending reward. [multiplier] is 2 after a rewarded ad.
  ResourceBag claim(GameState s, {double multiplier = 1}) {
    final r = s.pendingOfflineReward;
    if (r == null) return ResourceBag();
    final bag = r.gained.scaled(multiplier);
    engine.grantResources(s, bag);
    if (r.creditedSeconds > 0) s.addStat(Metric.offlineClaims, 1);
    s.pendingOfflineReward = null;
    return bag;
  }
}
