import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/prestige_system.dart';
import 'package:idle_orbit/game/engine/progression_system.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';

import '../helpers.dart';

void main() {
  final config = loadBalance();
  final engine = GameEngine(config);
  final prestige = PrestigeSystem(engine);
  final prog = ProgressionSystem(engine);

  group('prestige', () {
    GameState ready() {
      final s = engine.newGame(t0)
        ..unlockedPlanets.addAll(['glacies', 'dunebell'])
        ..runStats[Metric.runAlloy] = 2000 * 100 // => 10 points
        ..facilities['ore_mine'] = 50
        ..research['drill_tech'] = 3
        ..robots['miner_bot'] = 5
        ..entitlements.add('starter_pack')
        ..robots['pioneer_bot'] = 3
        ..claimedAchievements.add('a_ore_1');
      return s;
    }

    test('requires the configured planet', () {
      final s = engine.newGame(t0)..runStats[Metric.runAlloy] = 1e9;
      expect(prestige.canPrestige(s), isFalse);
    });

    test('resets run, keeps meta, awards points', () {
      final s = ready();
      expect(prestige.pointsAvailable(s), 10);
      expect(prestige.prestige(s, t0), 10);
      expect(s.prestigePoints, 10);
      expect(s.facilityLevel('ore_mine'), 1);
      expect(s.researchLevel('drill_tech'), 0);
      expect(s.robotLevel('miner_bot'), 0);
      expect(s.robotLevel('pioneer_bot'), 3, reason: 'purchased robot kept');
      expect(s.unlockedPlanets, {'terra_nova'});
      expect(s.claimedAchievements, contains('a_ore_1'));
      expect(s.stat(Metric.prestigeCount), 1);
      expect(s.runStat(Metric.runAlloy), 0);
    });

    test('upgrades boost production and starting resources', () {
      final s = ready();
      prestige.prestige(s, t0);
      final before = engine.modifiers(s).production[ResourceType.ore]!;
      expect(prestige.buyUpgrade(s, 'pp_production'), isTrue);
      expect(engine.modifiers(s).production[ResourceType.ore]!, closeTo(before * 1.25, 1e-9));
      expect(prestige.buyUpgrade(s, 'pp_start'), isTrue);
      s.runStats[Metric.runAlloy] = 2000;
      s.unlockedPlanets.addAll(['glacies', 'dunebell']);
      prestige.prestige(s, t0);
      expect(s.resources[ResourceType.alloy], closeTo(50, 1e-9));
    });
  });

  group('daily', () {
    test('missions are picked per day and roll forward only', () {
      final s = engine.newGame(t0);
      expect(prog.ensureDaily(s, '2026-11-08'), isTrue);
      expect(s.daily.missionIds.length, config.dailyMissionCount);
      final ids = List.of(s.daily.missionIds);
      expect(prog.ensureDaily(s, '2026-11-08'), isFalse);
      expect(prog.ensureDaily(s, '2026-11-07'), isFalse, reason: 'no rollback');
      expect(s.daily.missionIds, ids);
      expect(prog.ensureDaily(s, '2026-11-09'), isTrue);
    });

    test('mission progress uses daily delta and claims once', () {
      final s = engine.newGame(t0)..stats[Metric.facilityUpgrades] = 100;
      prog.ensureDaily(s, '2026-11-08');
      s.daily.missionIds = ['m_upgrade_10'];
      expect(prog.missions(s).single.progress, 0);
      s.addStat(Metric.facilityUpgrades, 10);
      expect(prog.missions(s).single.complete, isTrue);
      expect(prog.claimMission(s, 'm_upgrade_10', t0), isNotNull);
      expect(prog.claimMission(s, 'm_upgrade_10', t0), isNull);
    });

    test('login reward once per day, cycles', () {
      final s = engine.newGame(t0);
      prog.ensureDaily(s, '2026-11-08');
      expect(prog.claimLogin(s, t0), isNotNull);
      expect(prog.claimLogin(s, t0), isNull);
      prog.ensureDaily(s, '2026-11-09');
      expect(prog.canClaimLogin(s), isTrue);
      prog.claimLogin(s, t0);
      expect(s.daily.loginDayIndex, 2);
    });
  });

  group('achievements', () {
    test('unlock by metric, claim adds production bonus', () {
      final s = engine.newGame(t0);
      expect(prog.claimAchievement(s, 'a_ore_1'), isFalse);
      s.stats[Metric.lifetimeOre] = 1000;
      final before = engine.modifiers(s).production[ResourceType.ore]!;
      expect(prog.claimAchievement(s, 'a_ore_1'), isTrue);
      expect(engine.modifiers(s).production[ResourceType.ore]!, closeTo(before * 1.02, 1e-9));
      expect(prog.claimAchievement(s, 'a_ore_1'), isFalse);
    });
  });
}
