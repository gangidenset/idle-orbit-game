import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';

import '../helpers.dart';

void main() {
  final config = loadBalance();
  final engine = GameEngine(config);

  group('config', () {
    test('balance.json parses and validates', () {
      expect(config.facilities.length, 5);
      expect(config.planets.length, 5);
      expect(config.offline.baseCapHours, 8);
    });
  });

  group('production', () {
    test('new game produces ore over time', () {
      final s = engine.newGame(t0);
      final before = s.resources[ResourceType.ore];
      engine.tick(s, 10, nowMs: t0);
      expect(s.resources[ResourceType.ore], greaterThan(before));
      expect(s.stat(Metric.lifetimeOre), closeTo(10, 0.01));
    });

    test('production stops at storage cap but rewards may exceed it', () {
      final s = engine.newGame(t0);
      final cap = engine.storageCap(s, ResourceType.ore);
      engine.tick(s, 100000, nowMs: t0);
      expect(s.resources[ResourceType.ore], closeTo(cap, 1e-6));
      engine.grantResources(s, ResourceBag({ResourceType.ore: 500}));
      expect(s.resources[ResourceType.ore], closeTo(cap + 500, 1e-6));
      engine.tick(s, 10, nowMs: t0);
      expect(s.resources[ResourceType.ore], closeTo(cap + 500, 1e-6),
          reason: 'cap must not delete overflow from rewards');
    });

    test('converter throttles when inputs run short', () {
      final s = engine.newGame(t0)
        ..facilities['alloy_smelter'] = 5
        ..facilities['ore_mine'] = 0
        ..resources = ResourceBag({ResourceType.ore: 1, ResourceType.energy: 1000});
      final snap = engine.snapshot(s, nowMs: t0, dt: 1);
      expect(snap.of('alloy_smelter')!.efficiency, lessThan(1));
      engine.tick(s, 1, nowMs: t0);
      expect(s.resources[ResourceType.ore], greaterThanOrEqualTo(0));
    });

    test('milestones multiply production', () {
      expect(engine.milestoneMultiplier(9), 1);
      expect(engine.milestoneMultiplier(10), 2);
      expect(engine.milestoneMultiplier(25), 4);
    });

    test('boost doubles production and expires', () {
      final s = engine.newGame(t0);
      final base = engine.snapshot(s, nowMs: t0).gross[ResourceType.ore];
      engine.addBoost(s, source: 'ad', multiplier: 2, minutes: 30, nowMs: t0);
      expect(engine.snapshot(s, nowMs: t0).gross[ResourceType.ore], closeTo(base * 2, 1e-9));
      expect(engine.snapshot(s, nowMs: t0 + 31 * 60000).gross[ResourceType.ore],
          closeTo(base, 1e-9));
    });

    test('ad boosts extend up to the stack limit', () {
      final s = engine.newGame(t0);
      for (var i = 0; i < 20; i++) {
        engine.addBoost(s,
            source: 'ad', multiplier: 2, minutes: 30, maxStackMinutes: 240, nowMs: t0);
      }
      expect(engine.boostRemaining(s, 'ad', t0).inMinutes, 240);
      expect(engine.boostMultiplier(s, t0), 2, reason: 'same source must not stack x2^n');
    });
  });

  group('facilities', () {
    test('upgrade costs grow and are paid', () {
      final s = engine.newGame(t0)..resources[ResourceType.ore] = 1000;
      final c1 = engine.facilityCost(s, 'ore_mine')[ResourceType.ore];
      expect(engine.upgradeFacility(s, 'ore_mine'), isTrue);
      final c2 = engine.facilityCost(s, 'ore_mine')[ResourceType.ore];
      expect(c2, greaterThan(c1));
      expect(s.resources[ResourceType.ore], closeTo(1000 - c1, 1e-9));
      expect(s.facilityLevel('ore_mine'), 2);
    });

    test('locked facility cannot be upgraded', () {
      final s = engine.newGame(t0)..resources[ResourceType.ore] = 1e9;
      expect(engine.facilityBlock(s, 'alloy_smelter'), UpgradeBlock.locked);
      expect(engine.upgradeFacility(s, 'alloy_smelter'), isFalse);
    });

    test('insufficient resources block upgrade', () {
      final s = engine.newGame(t0)..resources[ResourceType.ore] = 0;
      expect(engine.facilityBlock(s, 'ore_mine'), UpgradeBlock.insufficient);
    });

    test('affordable levels matches repeated upgrades', () {
      final s = engine.newGame(t0)..resources[ResourceType.ore] = 500;
      final n = engine.affordableFacilityLevels(s, 'ore_mine');
      expect(engine.upgradeFacilityMany(s, 'ore_mine', 1000), n);
    });

    test('storage upgrade raises the cap', () {
      final s = engine.newGame(t0);
      final c0 = engine.storageCap(s, ResourceType.ore);
      s.facilities['storage'] = 1;
      expect(engine.storageCap(s, ResourceType.ore), greaterThan(c0));
      expect(engine.storageCap(s, ResourceType.research), double.infinity);
    });
  });

  group('robots & research', () {
    test('hiring a robot increases production', () {
      final s = engine.newGame(t0)..resources[ResourceType.ore] = 10000;
      final before = engine.snapshot(s, nowMs: t0).gross[ResourceType.ore];
      expect(engine.upgradeRobot(s, 'miner_bot'), isTrue);
      final after = engine.snapshot(s, nowMs: t0).gross[ResourceType.ore];
      expect(after, closeTo(before * 1.1, 1e-9));
    });

    test('robots locked behind planets / entitlements', () {
      final s = engine.newGame(t0)..resources[ResourceType.alloy] = 1e9;
      expect(engine.robotBlock(s, 'analyst_bot'), UpgradeBlock.locked);
      expect(engine.robotBlock(s, 'pioneer_bot'), UpgradeBlock.locked);
    });

    test('research consumes points and applies effect', () {
      final s = engine.newGame(t0)..resources[ResourceType.research] = 10;
      final before = engine.snapshot(s, nowMs: t0).gross[ResourceType.ore];
      expect(engine.doResearch(s, 'drill_tech'), isTrue);
      expect(s.resources[ResourceType.research], closeTo(0, 1e-9));
      expect(engine.snapshot(s, nowMs: t0).gross[ResourceType.ore],
          closeTo(before * 1.15, 1e-9));
    });

    test('cost reduction research discounts facility cost', () {
      final s = engine.newGame(t0);
      final c0 = engine.facilityCost(s, 'ore_mine')[ResourceType.ore];
      s.research['logistics'] = 2;
      expect(engine.facilityCost(s, 'ore_mine')[ResourceType.ore], closeTo(c0 * 0.94, 1e-9));
    });
  });

  group('planets', () {
    test('planets unlock in order and grant multiplier', () {
      final s = engine.newGame(t0)
        ..resources[ResourceType.alloy] = 1e9
        ..resources[ResourceType.research] = 1e9;
      expect(engine.canUnlockPlanet(s, 'dunebell'), isFalse, reason: 'must go in order');
      final before = engine.modifiers(s).production[ResourceType.ore]!;
      expect(engine.unlockPlanet(s, 'glacies'), isTrue);
      expect(s.activePlanet, 'glacies');
      final after = engine.modifiers(s).production[ResourceType.ore]!;
      expect(after, greaterThan(before));
      // Active bonus: energy x2 on glacies.
      expect(engine.modifiers(s).production[ResourceType.energy]! / after, closeTo(2, 1e-9));
    });
  });

  group('player level', () {
    test('xp yields levels', () {
      final s = engine.newGame(t0);
      expect(engine.playerLevel(s), 1);
      s.xp = engine.xpToNext(1);
      expect(engine.playerLevel(s), 2);
    });
  });

  group('purchases', () {
    test('applyPurchase is idempotent per transaction', () {
      final s = engine.newGame(t0);
      final p = config.shop.byId('boost_24h')!;
      expect(engine.applyPurchase(s, p, 'tx1', t0), isTrue);
      expect(engine.applyPurchase(s, p, 'tx1', t0), isFalse);
      expect(engine.boostRemaining(s, 'iap', t0).inHours, 24);
    });

    test('non-consumable restore does not double grant', () {
      final s = engine.newGame(t0);
      final p = config.shop.byId('starter_pack')!;
      expect(engine.applyPurchase(s, p, 'a', t0), isTrue);
      final alloy = s.resources[ResourceType.alloy];
      expect(engine.applyPurchase(s, p, 'b', t0), isFalse);
      expect(s.resources[ResourceType.alloy], alloy);
      expect(s.robotLevel('pioneer_bot'), 1);
    });

    test('no_ads entitlement disables interstitials, premium skips rewarded', () {
      final s = engine.newGame(t0);
      expect(engine.noAds(s), isFalse);
      s.entitlements.add('no_ads');
      expect(engine.noAds(s), isTrue);
      expect(engine.skipsRewardedAds(s), isFalse);
      s.entitlements.add('premium');
      expect(engine.skipsRewardedAds(s), isTrue);
    });
  });
}
