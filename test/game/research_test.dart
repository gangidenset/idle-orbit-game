import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/notification_planner.dart';
import 'package:idle_orbit/game/engine/offline_calculator.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';

import '../helpers.dart';
import 'controller_test.dart' show ScriptedAds, FakeStore, FakeNotifications;

void main() {
  final config = loadBalance();
  final engine = GameEngine(config);

  GameState rich() => engine.newGame(t0)..resources[ResourceType.research] = 1e12;

  group('timed research', () {
    test('durations grow per level and are capped', () {
      for (final n in config.research) {
        expect(engine.researchDuration(n.id, 0), greaterThan(0), reason: n.id);
        expect(engine.researchDuration(n.id, 1), greaterThan(engine.researchDuration(n.id, 0)));
        expect(engine.researchDuration(n.id, n.maxLevel - 1), lessThanOrEqualTo(config.researchMaxSeconds));
      }
    });

    test('one research at a time; level only rises on completion', () {
      final s = rich();
      expect(engine.doResearch(s, 'drill_tech'), isTrue);
      expect(s.researchLevel('drill_tech'), 0);
      expect(engine.researchBlock(s, 'solar_tech'), UpgradeBlock.busy);
      expect(engine.doResearch(s, 'solar_tech'), isFalse);
      final d = engine.researchDuration('drill_tech', 0);
      expect(engine.advanceResearch(s, d / 2), isNull);
      expect(engine.researchRemaining(s), closeTo(d / 2, 1e-9));
      expect(engine.advanceResearch(s, d), 'drill_tech');
      expect(s.researchLevel('drill_tech'), 1);
      expect(s.activeResearch, isNull);
      expect(engine.researchBlock(s, 'solar_tech'), UpgradeBlock.none);
    });

    test('spamming cannot max research instantly', () {
      final s = rich();
      for (var i = 0; i < 1000; i++) {
        for (final n in config.research) {
          engine.doResearch(s, n.id);
        }
        engine.advanceResearch(s, 1);
      }
      final total = config.research.fold<int>(0, (a, n) => a + s.researchLevel(n.id));
      final max = config.research.fold<int>(0, (a, n) => a + n.maxLevel);
      expect(total, lessThan(max ~/ 3), reason: '1000 s of play must not finish the tree');
    });

    test('research survives save/load', () {
      final s = rich();
      engine.doResearch(s, 'smelt_tech');
      engine.advanceResearch(s, 5);
      final back = GameState.fromJson(s.toJson());
      expect(back.activeResearch, 'smelt_tech');
      expect(back.researchProgress, closeTo(5, 1e-9));
    });

    test('progresses on credited offline time', () {
      final offline = OfflineCalculator(engine);
      final s = rich();
      engine.doResearch(s, 'logistics');
      s.lastSeenMs = t0;
      s.highWaterMs = t0;
      final r = offline.computeAndStore(s, t0 + hourMs)!;
      expect(r.researchDone, ['logistics']);
      expect(s.researchLevel('logistics'), 1);
    });

    test('a reminder is planned for research finishing while away', () {
      final s = rich()..research['autonomy'] = 3;
      engine.doResearch(s, 'autonomy');
      final plan = NotificationPlanner(engine).plan(s, t0);
      final r = plan.where((p) => p.kind == ReminderKind.researchDone).single;
      expect(r.delay.inSeconds, engine.researchDuration('autonomy', 3).round());
    });
  });

  test('rewarded ad shortens the current research', () async {
    final ads = ScriptedAds();
    final c = GameController(
      config: config,
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: ads,
      purchaseService: FakeStore(),
      analytics: LocalAnalyticsService(),
      notifications: FakeNotifications(),
      clock: FakeClock(t0),
    );
    await c.start();
    c.state.research['autonomy'] = 3;
    c.state.resources[ResourceType.research] = 1e12;
    expect(c.doResearch('autonomy'), isTrue);
    final before = c.engine.researchRemaining(c.state);
    expect(before, greaterThan(config.researchAdSpeedupMinutes * 60));

    ads.next = RewardedOutcome.dismissed;
    expect(await c.speedUpResearch(), isFalse);
    expect(c.engine.researchRemaining(c.state), before);

    ads.next = RewardedOutcome.earned;
    final events = <GameEvent>[];
    final sub = c.events.listen(events.add);
    expect(await c.speedUpResearch(), isTrue);
    expect(c.engine.researchRemaining(c.state),
        closeTo(before - config.researchAdSpeedupMinutes * 60, 1e-6));
    // Finish it via ticking and get the completion event.
    c.advance(c.engine.researchRemaining(c.state) + 1);
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<ResearchCompletedEvent>().single.level, 4);
    await sub.cancel();
    c.dispose();
  });
}
