import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/offline_calculator.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';

import '../helpers.dart';

void main() {
  final config = loadBalance();
  final engine = GameEngine(config);
  final offline = OfflineCalculator(engine);

  GameState fresh() => engine.newGame(t0)..facilities['storage'] = 10;

  test('grants resources for time away, scaled by efficiency', () {
    final s = fresh();
    final rate = engine.snapshot(s, nowMs: t0).gross[ResourceType.ore];
    final r = offline.computeAndStore(s, t0 + hourMs)!;
    expect(r.creditedSeconds, 3600);
    expect(r.gained[ResourceType.ore],
        closeTo(rate * 3600 * config.offline.baseEfficiency, 1));
    expect(r.capped, isFalse);
  });

  test('caps at 8 hours', () {
    final s = fresh();
    final r = offline.computeAndStore(s, t0 + 24 * hourMs)!;
    expect(r.creditedSeconds, 8 * 3600);
    expect(r.elapsedSeconds, 24 * 3600);
    expect(r.capped, isTrue);
  });

  test('no reward below the minimum threshold', () {
    final s = fresh();
    expect(offline.computeAndStore(s, t0 + 30 * 1000), isNull);
  });

  test('clock rollback grants nothing and is flagged', () {
    final s = fresh();
    final r = offline.computeAndStore(s, t0 - 5 * hourMs)!;
    expect(r.clockAnomaly, isTrue);
    expect(r.gained.isEmpty, isTrue);
    expect(s.highWaterMs, t0, reason: 'high water must not move back');
  });

  test('rollback then forward cannot farm extra time', () {
    final s = fresh();
    // Forward 8h: legit claim.
    offline.computeAndStore(s, t0 + 8 * hourMs);
    offline.claim(s);
    // Roll back 8h and return again "8h later" (= same real moment).
    offline.computeAndStore(s, t0);
    offline.claim(s);
    final r = offline.computeAndStore(s, t0 + 8 * hourMs);
    expect(r?.creditedSeconds ?? 0, 0);
  });

  test('pending reward survives save/load and claim applies once', () {
    final s = fresh();
    offline.computeAndStore(s, t0 + hourMs);
    final restored = GameState.fromJson(s.toJson());
    expect(restored.pendingOfflineReward, isNotNull);
    final ore = restored.resources[ResourceType.ore];
    final got = offline.claim(restored, multiplier: 2);
    expect(restored.resources[ResourceType.ore], closeTo(ore + got[ResourceType.ore], 1e-6));
    expect(offline.claim(restored).isEmpty, isTrue, reason: 'no double claim');
    expect(restored.stat(Metric.offlineClaims), 1);
  });

  test('boost only applies while active during offline', () {
    final a = fresh();
    final b = fresh();
    engine.addBoost(b, source: 'ad', multiplier: 2, minutes: 30, nowMs: t0);
    final ra = offline.simulate(a, t0, 3600);
    final rb = offline.simulate(b, t0, 3600);
    final ratio = rb.gained[ResourceType.ore] / ra.gained[ResourceType.ore];
    expect(ratio, closeTo(1.5, 0.05)); // 30 of 60 minutes doubled
  });

  test('premium extends the offline cap', () {
    final s = fresh()..entitlements.add('premium');
    final r = offline.computeAndStore(s, t0 + 24 * hourMs)!;
    expect(r.creditedSeconds, 12 * 3600);
  });
}
