import 'dart:math' as math;

import '../model/game_state.dart';
import '../model/resources.dart';
import 'game_engine.dart';

/// 転生（星系ワープ）: resets the run in exchange for permanent points.
class PrestigeSystem {
  PrestigeSystem(this.engine);

  final GameEngine engine;

  bool isUnlocked(GameState s) =>
      s.unlockedPlanets.contains(engine.config.prestige.requiredPlanet) ||
      s.stat(Metric.prestigeCount) > 0;

  /// Points that a warp right now would award.
  int pointsAvailable(GameState s) {
    final p = engine.config.prestige;
    final metric = s.runStat(p.metric);
    if (metric <= 0) return 0;
    return math.pow(metric / p.pointsDivisor, p.pointsExponent).floor();
  }

  bool canPrestige(GameState s) =>
      s.unlockedPlanets.contains(engine.config.prestige.requiredPlanet) &&
      pointsAvailable(s) >= 1;

  /// Performs the warp. Returns points gained, or 0 if not allowed.
  int prestige(GameState s, int nowMs) {
    if (!canPrestige(s)) return 0;
    final gained = pointsAvailable(s);
    final fresh = engine.newGame(nowMs);

    s.prestigePoints += gained;
    s.addStat(Metric.prestigePointsEarned, gained.toDouble());
    s.addStat(Metric.prestigeCount, 1);

    // Reset run data only. Meta data (prestige, stats, missions,
    // achievements, purchases, settings, boosts) is preserved.
    s.resources = fresh.resources;
    s.facilities = fresh.facilities;
    s.robots = {
      // Purchased robots are an entitlement and survive the warp.
      if (s.has('starter_pack')) 'pioneer_bot': math.max(1, s.robotLevel('pioneer_bot')),
    };
    s.unlockedPlanets = fresh.unlockedPlanets;
    s.activePlanet = fresh.activePlanet;
    s.research = {};
    s.runStats = {};
    s.pendingOfflineReward = null;

    engine.grantResources(s, startingBonus(s));
    return gained;
  }

  ResourceBag startingBonus(GameState s) {
    final bag = ResourceBag();
    for (final u in engine.config.prestige.upgrades) {
      final lvl = s.prestigeLevel(u.id);
      if (lvl > 0 && !u.grantsPerLevel.isEmpty) {
        bag.addAll(u.grantsPerLevel.scaled(lvl.toDouble()));
      }
    }
    return bag;
  }

  double upgradeCost(GameState s, String id) {
    final u = engine.config.prestigeUpgrade(id);
    return u.costForLevel(s.prestigeLevel(id)).ceilToDouble();
  }

  UpgradeBlock upgradeBlock(GameState s, String id) {
    final u = engine.config.prestigeUpgrade(id);
    if (s.prestigeLevel(id) >= u.maxLevel) return UpgradeBlock.maxLevel;
    if (s.prestigePoints < upgradeCost(s, id)) return UpgradeBlock.insufficient;
    return UpgradeBlock.none;
  }

  bool buyUpgrade(GameState s, String id) {
    if (upgradeBlock(s, id) != UpgradeBlock.none) return false;
    s.prestigePoints -= upgradeCost(s, id);
    s.prestigeUpgrades[id] = s.prestigeLevel(id) + 1;
    return true;
  }
}
