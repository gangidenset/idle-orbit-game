import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/prestige_system.dart';
import 'package:idle_orbit/game/engine/visual_system.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';

import '../helpers.dart';

void main() {
  final config = loadBalance();
  final engine = GameEngine(config);
  final v = VisualSystem(engine);

  test('tiers follow the configured levels', () {
    expect(v.tierFor(0), 0);
    expect(v.tierFor(1), 1);
    expect(v.tierFor(9), 1);
    expect(v.tierFor(10), 2);
    expect(v.tierFor(200), 6);
    expect(v.nextTierLevel(10), 25);
    expect(v.nextTierLevel(200), isNull);
    final mine = config.facility('ore_mine');
    expect(v.tierName(mine, 1), '採掘リグ');
    expect(v.tierName(mine, 10), '採掘プラント');
  });

  test('every facility names every tier', () {
    for (final f in config.facilities) {
      expect(f.tierNames, hasLength(config.visuals.tierLevels.length), reason: f.id);
    }
  });

  test('decorations unlock from progress', () {
    final s = engine.newGame(t0);
    expect(v.activeDecorations(s), isEmpty);
    s.research['drill_tech'] = 3;
    s.robots
      ..['miner_bot'] = 1
      ..['power_drone'] = 1
      ..['smelter_bot'] = 1;
    s.stats[Metric.prestigeCount] = 1;
    s.entitlements.add('premium');
    final ids = v.activeDecorations(s).map((d) => d.id).toSet();
    expect(ids, containsAll(['city_lights', 'comm_array', 'warp_halo', 'aurora']));
    expect(ids, isNot(contains('station')), reason: 'needs player level 10');
  });

  test('evolutions only when crossing into tier 2+', () {
    final a = engine.newGame(t0);
    final before = v.look(a);
    a.facilities['ore_mine'] = 9;
    expect(v.evolutions(before, v.look(a)), isEmpty);
    a.facilities['ore_mine'] = 30; // jumps past Lv10 and Lv25
    final evo = v.evolutions(before, v.look(a));
    expect(evo.single.tier, 3);
    expect(evo.single.name, '深層掘削基地');
    // Building a facility for the first time (tier 0 -> 1) is not an evolution.
    final b = engine.newGame(t0);
    final b0 = v.look(b);
    b.facilities['power_plant'] = 1;
    expect(v.evolutions(b0, v.look(b)), isEmpty);
  });

  test('controller emits evolution and decoration events', () async {
    final c = GameController(
      config: config,
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: const DisabledAdService(),
      purchaseService: UnavailablePurchaseService(),
      analytics: LocalAnalyticsService(),
      clock: FakeClock(t0),
    );
    await c.start();
    final events = <GameEvent>[];
    final sub = c.events.listen(events.add);
    c.state.resources[ResourceType.ore] = 1e9;
    c.state.facilities['storage'] = 30;

    Iterable<Evolution> mineEvolutions() => events
        .whereType<FacilityEvolvedEvent>()
        .map((e) => e.evolution)
        .where((e) => e.facility.id == 'ore_mine');

    c.upgradeFacility('ore_mine', count: 5); // Lv1 -> 6: no evolution
    await Future<void>.delayed(Duration.zero);
    expect(mineEvolutions(), isEmpty);

    c.upgradeFacility('ore_mine', count: 4); // -> Lv10
    await Future<void>.delayed(Duration.zero);
    final evo = mineEvolutions().single;
    expect(evo.facility.id, 'ore_mine');
    expect(evo.name, '採掘プラント');
    expect(c.evolvedAtMs, contains('ore_mine'));

    for (final id in ['miner_bot', 'power_drone']) {
      c.upgradeRobot(id);
    }
    c.state.resources[ResourceType.alloy] = 1e6;
    c.upgradeRobot('smelter_bot'); // third robot type -> comm array
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<DecorationUnlockedEvent>().map((e) => e.decoration.id),
        contains('comm_array'));
    await sub.cancel();
    c.dispose();
  });

  test('monuments: first planet from the start, one per planet reached, kept across warps', () {
    final prestige = PrestigeSystem(engine);
    final s = engine.newGame(t0)
      ..resources[ResourceType.alloy] = 1e15
      ..resources[ResourceType.research] = 1e15;
    expect(v.monuments(s).map((p) => p.id), ['terra_nova']);
    engine.unlockPlanet(s, 'glacies');
    engine.unlockPlanet(s, 'dunebell');
    expect(v.monuments(s).map((p) => p.id), ['terra_nova', 'glacies', 'dunebell']);

    s.runStats[Metric.runAlloy] = 1e9;
    expect(prestige.prestige(s, t0), greaterThan(0));
    expect(s.unlockedPlanets, {'terra_nova'}, reason: 'warp resets the planets');
    expect(v.monuments(s), hasLength(3), reason: 'but the monuments stay');
  });

  test('planet unlock event reports a new monument only the first time', () async {
    final c = GameController(
      config: config,
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: const DisabledAdService(),
      purchaseService: UnavailablePurchaseService(),
      analytics: LocalAnalyticsService(),
      clock: FakeClock(t0),
    );
    await c.start();
    final events = <PlanetUnlockedEvent>[];
    final sub = c.events.listen((e) {
      if (e is PlanetUnlockedEvent) events.add(e);
    });
    void rich() => c.state
      ..resources[ResourceType.alloy] = 1e15
      ..resources[ResourceType.research] = 1e15;

    rich();
    c.unlockPlanet('glacies');
    c.unlockPlanet('dunebell');
    c.state.runStats[Metric.runAlloy] = 1e9;
    c.doPrestige();
    rich();
    c.unlockPlanet('glacies'); // again, after the warp
    await Future<void>.delayed(Duration.zero);
    expect(events.map((e) => (e.planet.id, e.newMonument)),
        [('glacies', true), ('dunebell', true), ('glacies', false)]);
    await sub.cancel();
    c.dispose();
  });
}
