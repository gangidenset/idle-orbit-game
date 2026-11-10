import 'package:idle_orbit/game/config/balance_config.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/prestige_system.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';

/// A simple greedy player shared by the balance simulators.
class SimBot {
  SimBot(this.config)
      : engine = GameEngine(config),
        prestige = PrestigeSystem(GameEngine(config));

  final BalanceConfig config;
  final GameEngine engine;
  final PrestigeSystem prestige;

  static double weight(ResourceBag c) =>
      c[ResourceType.ore] +
      c[ResourceType.energy] * 2 +
      c[ResourceType.alloy] * 20 +
      c[ResourceType.research] * 100;

  /// Unlocks the next planet if possible. Returns its id.
  String? tryUnlockPlanet(GameState s) {
    final next = engine.nextLockedPlanet(s);
    if (next != null && engine.unlockPlanet(s, next.id)) return next.id;
    return null;
  }

  /// Spends resources: research first, then the cheapest facility/robot.
  void spend(GameState s) {
    for (final r in config.research) {
      engine.doResearch(s, r.id);
    }
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

  /// Spends warp points on the cheapest available prestige upgrade.
  void spendPrestige(GameState s) {
    while (true) {
      String? best;
      var bestCost = double.infinity;
      for (final u in config.prestige.upgrades) {
        if (prestige.upgradeBlock(s, u.id) != UpgradeBlock.none) continue;
        final c = prestige.upgradeCost(s, u.id);
        if (c < bestCost) {
          bestCost = c;
          best = u.id;
        }
      }
      if (best == null || !prestige.buyUpgrade(s, best)) return;
    }
  }
}
