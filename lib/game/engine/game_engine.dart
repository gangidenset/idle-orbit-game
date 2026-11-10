import 'dart:math' as math;

import '../config/balance_config.dart';
import '../model/game_state.dart';
import '../model/resources.dart';

/// Aggregated multipliers derived from robots, research, planets, prestige,
/// achievements, player level and entitlements. Boosts are applied separately
/// because they depend on time.
class Modifiers {
  Modifiers({
    required this.production,
    required this.offlineEfficiency,
    required this.offlineCapHours,
    required this.costDiscount,
    required this.storageCapMultiplier,
  });

  final Map<ResourceType, double> production;
  final double offlineEfficiency;
  final double offlineCapHours;
  final double costDiscount;
  final double storageCapMultiplier;
}

/// Output of one facility in a [ProductionSnapshot].
class FacilityOutput {
  FacilityOutput(this.id, this.output, this.input, this.efficiency);
  final String id;

  /// Per second, at 100% efficiency.
  final ResourceBag output;
  final ResourceBag input;

  /// 0..1 — converters slow down when inputs run short.
  final double efficiency;
}

class ProductionSnapshot {
  ProductionSnapshot(this.facilities, this.gross, this.consumed, this.boost);

  final List<FacilityOutput> facilities;

  /// Per second produced (after efficiency).
  final ResourceBag gross;

  /// Per second consumed (after efficiency).
  final ResourceBag consumed;
  final double boost;

  ResourceBag get net => gross - consumed;

  FacilityOutput? of(String id) {
    for (final f in facilities) {
      if (f.id == id) return f;
    }
    return null;
  }
}

enum UpgradeBlock { none, maxLevel, locked, insufficient }

/// Pure game rules. Has no Flutter dependency and never reads the clock:
/// every time-dependent call receives `nowMs` so tests are deterministic.
class GameEngine {
  GameEngine(this.config);

  final BalanceConfig config;

  // ---------------------------------------------------------------- new game

  GameState newGame(int nowMs) => GameState(
        createdAtMs: nowMs,
        lastSeenMs: nowMs,
        highWaterMs: nowMs,
        resources: config.startingResources.copy(),
        facilities: {for (final f in config.facilities) f.id: f.startLevel},
        robots: {},
        unlockedPlanets: {config.planets.first.id},
        activePlanet: config.planets.first.id,
        research: {},
      );

  // --------------------------------------------------------------- modifiers

  double _sumEffects(
    GameState s,
    EffectType type, {
    ResourceType? resource,
    bool includeRobots = true,
  }) {
    double sumOf(Effect e, int level) =>
        e.type == type && (resource == null || e.appliesTo(resource))
            ? e.perLevel * level
            : 0;

    var research = 0.0;
    for (final r in config.research) {
      research += sumOf(r.effect, s.researchLevel(r.id));
    }
    var prestige = 0.0;
    for (final u in config.prestige.upgrades) {
      prestige += sumOf(u.effect, s.prestigeLevel(u.id));
    }
    var robots = 0.0;
    if (includeRobots) {
      for (final r in config.robots) {
        if (!isRobotUnlocked(s, r)) continue;
        robots += sumOf(r.effect, s.robotLevel(r.id));
      }
      robots *= 1 + robotPower(s);
    }
    return research + prestige + robots;
  }

  double robotPower(GameState s) =>
      _sumEffects(s, EffectType.robotPower, includeRobots: false);

  double achievementBonus(GameState s) {
    var b = 0.0;
    for (final a in config.achievements) {
      if (s.claimedAchievements.contains(a.id)) b += a.productionBonus;
    }
    return b;
  }

  bool hasPremium(GameState s) => s.has('premium');

  /// Passive bonus from all warp points ever earned (e.g. 0.5 = +50%).
  double earnedPointsBonus(GameState s) =>
      s.stat(Metric.prestigePointsEarned) * config.prestige.productionPerEarnedPoint;

  Modifiers modifiers(GameState s) {
    final level = playerLevel(s);
    var planetPerm = 1.0;
    for (final p in config.planets) {
      if (s.unlockedPlanets.contains(p.id)) planetPerm *= p.permanentMultiplier;
    }
    final active = config.planet(s.activePlanet);
    final premium = hasPremium(s) ? config.shop.premiumProductionBonus : 0.0;
    final common = planetPerm *
        (1 + earnedPointsBonus(s)) *
        (1 + achievementBonus(s)) *
        (1 + (level - 1) * config.player.productionBonusPerLevel) *
        (1 + premium);

    // Robots, research and prestige are grouped into separate multiplicative
    // buckets so each system stays meaningful.
    double bucket(ResourceType r, Iterable<(Effect, int)> items) {
      var sum = 0.0;
      for (final (e, lvl) in items) {
        if (e.type == EffectType.production && e.appliesTo(r)) {
          sum += e.perLevel * lvl;
        }
      }
      return sum;
    }

    final rp = 1 + robotPower(s);
    final production = <ResourceType, double>{};
    for (final r in ResourceType.values) {
      final robots = bucket(r, [
            for (final x in config.robots)
              if (isRobotUnlocked(s, x)) (x.effect, s.robotLevel(x.id)),
          ]) *
          rp;
      final research =
          bucket(r, [for (final x in config.research) (x.effect, s.researchLevel(x.id))]);
      final prestige = bucket(r, [
        for (final x in config.prestige.upgrades) (x.effect, s.prestigeLevel(x.id)),
      ]);
      production[r] = (1 + robots) *
          (1 + research) *
          (1 + prestige) *
          (active.activeBonus[r] ?? 1) *
          common;
    }

    return Modifiers(
      production: production,
      offlineEfficiency: config.offline.baseEfficiency +
          _sumEffects(s, EffectType.offlineEfficiency),
      offlineCapHours: config.offline.baseCapHours +
          _sumEffects(s, EffectType.offlineCapHours) +
          (hasPremium(s) ? config.shop.premiumOfflineCapHours : 0),
      costDiscount: math.min(0.9, _sumEffects(s, EffectType.costReduction)),
      storageCapMultiplier: 1 + _sumEffects(s, EffectType.storageCap),
    );
  }

  // ------------------------------------------------------------------ boosts

  double boostMultiplier(GameState s, int nowMs) {
    var m = 1.0;
    for (final b in s.boosts) {
      if (b.activeAt(nowMs)) m *= b.multiplier;
    }
    return m;
  }

  /// Remaining time of the boost from [source], or zero.
  Duration boostRemaining(GameState s, String source, int nowMs) {
    for (final b in s.boosts) {
      if (b.source == source && b.activeAt(nowMs)) {
        return Duration(milliseconds: b.endMs - nowMs);
      }
    }
    return Duration.zero;
  }

  /// Adds or extends a boost. Boosts from the same source extend each other
  /// (up to [maxStackMinutes] from now); different sources multiply.
  void addBoost(
    GameState s, {
    required String source,
    required double multiplier,
    required double minutes,
    required int nowMs,
    double? maxStackMinutes,
  }) {
    s.boosts.removeWhere((b) => !b.activeAt(nowMs));
    final existing = s.boosts.where((b) => b.source == source).toList();
    final base = existing.isEmpty ? nowMs : existing.first.endMs;
    var end = base + (minutes * 60000).round();
    if (maxStackMinutes != null) {
      end = math.min(end, nowMs + (maxStackMinutes * 60000).round());
    }
    s.boosts.removeWhere((b) => b.source == source);
    s.boosts.add(Boost(multiplier: multiplier, endMs: end, source: source));
  }

  bool canExtendAdBoost(GameState s, int nowMs) =>
      boostRemaining(s, 'ad', nowMs).inSeconds <
      config.adBoost.maxStackMinutes * 60 - 60;

  // ---------------------------------------------------------------- storage

  /// Storage cap for [r], or `double.infinity` for uncapped resources.
  double storageCap(GameState s, ResourceType r, [Modifiers? mods]) {
    final base = config.storage.baseCap[r];
    if (base <= 0) return double.infinity;
    final lvl = s.facilityLevel(config.storage.facilityId);
    final m = mods ?? modifiers(s);
    return base * math.pow(config.storage.capGrowthPerLevel, lvl) * m.storageCapMultiplier;
  }

  // ------------------------------------------------------------- production

  double milestoneMultiplier(int level) {
    var m = 1.0;
    for (final ms in config.milestones) {
      if (level >= ms.level) m *= ms.multiplier;
    }
    return m;
  }

  /// Next milestone level above [level], or null.
  int? nextMilestone(int level) {
    for (final ms in config.milestones) {
      if (ms.level > level) return ms.level;
    }
    return null;
  }

  /// Computes production for a [dt] step given current stock.
  ProductionSnapshot snapshot(
    GameState s, {
    required int nowMs,
    double dt = 1,
    Modifiers? mods,
    double? boostOverride,
  }) {
    final m = mods ?? modifiers(s);
    final boost = boostOverride ?? boostMultiplier(s, nowMs);
    final outputs = <String, ResourceBag>{};
    final inputs = <String, ResourceBag>{};
    final producerGross = ResourceBag();
    final demand = ResourceBag();

    for (final f in config.facilities) {
      final lvl = s.facilityLevel(f.id);
      if (lvl <= 0 || f.produces.isEmpty) continue;
      final ms = milestoneMultiplier(lvl);
      final out = ResourceBag();
      for (final e in f.produces.nonZero) {
        out[e.key] = e.value * lvl * ms * m.production[e.key]! * boost;
      }
      final inp = f.consumes.scaled(lvl.toDouble());
      outputs[f.id] = out;
      inputs[f.id] = inp;
      if (f.isConverter) {
        demand.addAll(inp);
      } else {
        producerGross.addAll(out);
      }
    }

    // Shared inputs are allocated proportionally between converters.
    final ratio = <ResourceType, double>{};
    for (final r in ResourceType.values) {
      final need = demand[r] * dt;
      if (need <= 0) {
        ratio[r] = 1;
      } else {
        final available = s.resources[r] + producerGross[r] * dt;
        ratio[r] = (available / need).clamp(0.0, 1.0);
      }
    }

    final list = <FacilityOutput>[];
    final gross = producerGross.copy();
    final consumed = ResourceBag();
    for (final f in config.facilities) {
      final out = outputs[f.id];
      if (out == null) continue;
      final inp = inputs[f.id]!;
      var eff = 1.0;
      if (f.isConverter) {
        for (final e in inp.nonZero) {
          eff = math.min(eff, ratio[e.key]!);
        }
        gross.addAll(out.scaled(eff));
        consumed.addAll(inp.scaled(eff));
      }
      list.add(FacilityOutput(f.id, out, inp, eff));
    }
    return ProductionSnapshot(list, gross, consumed, boost);
  }

  /// Advances the simulation by [dt] seconds. Returns what was produced.
  ///
  /// Production stops at the storage cap; amounts already above the cap
  /// (from rewards/purchases) are never reduced by the cap.
  ResourceBag tick(
    GameState s,
    double dt, {
    required int nowMs,
    bool active = true,
    Modifiers? mods,
  }) {
    if (dt <= 0) return ResourceBag();
    final m = mods ?? modifiers(s);
    final snap = snapshot(s, nowMs: nowMs, dt: dt, mods: m);
    final produced = ResourceBag();
    for (final r in ResourceType.values) {
      final old = s.resources[r];
      final cap = storageCap(s, r, m);
      final add = snap.gross[r] * dt;
      final sub = snap.consumed[r] * dt;
      var v = old - sub;
      if (v < 0) v = 0;
      final room = math.max(0.0, cap - v);
      final credited = math.min(add, room);
      v += credited;
      s.resources[r] = v;
      produced[r] = credited;
      if (credited > 0) {
        s.addStat(Metric.lifetimeFor(r), credited);
      }
    }
    s.addRunStat(Metric.runOre, produced[ResourceType.ore]);
    s.addRunStat(Metric.runAlloy, produced[ResourceType.alloy]);
    if (active) {
      s.addStat(Metric.playSeconds, dt);
      final oreRate = snap.gross[ResourceType.ore];
      if (oreRate > 0) {
        s.addStat(Metric.oreMinutes,
            (produced[ResourceType.ore] / (oreRate * dt)) * dt / 60);
      }
    }
    return produced;
  }

  // ------------------------------------------------------------- facilities

  bool isFacilityUnlocked(GameState s, FacilityConfig f) =>
      f.requires.entries.every((e) => s.facilityLevel(e.key) >= e.value);

  ResourceBag facilityCost(GameState s, String id, [Modifiers? mods]) {
    final f = config.facility(id);
    final m = mods ?? modifiers(s);
    return f.costForLevel(s.facilityLevel(id), discount: m.costDiscount);
  }

  UpgradeBlock facilityBlock(GameState s, String id) {
    final f = config.facility(id);
    if (!isFacilityUnlocked(s, f)) return UpgradeBlock.locked;
    if (!s.resources.covers(facilityCost(s, id))) return UpgradeBlock.insufficient;
    return UpgradeBlock.none;
  }

  bool upgradeFacility(GameState s, String id) {
    if (facilityBlock(s, id) != UpgradeBlock.none) return false;
    _pay(s, facilityCost(s, id));
    s.facilities[id] = s.facilityLevel(id) + 1;
    s.addStat(Metric.facilityUpgrades, 1);
    s.xp += config.player.xpPerFacilityUpgrade;
    return true;
  }

  /// How many levels can be bought right now (capped at [limit]).
  int affordableFacilityLevels(GameState s, String id, {int limit = 100}) {
    final f = config.facility(id);
    if (!isFacilityUnlocked(s, f)) return 0;
    final m = modifiers(s);
    final budget = s.resources.copy();
    var lvl = s.facilityLevel(id);
    var n = 0;
    while (n < limit) {
      final c = f.costForLevel(lvl, discount: m.costDiscount);
      if (!budget.covers(c)) break;
      budget.addAll(c.scaled(-1));
      lvl++;
      n++;
    }
    return n;
  }

  /// Total cost of the next [n] levels.
  ResourceBag facilityCostMany(GameState s, String id, int n) {
    final f = config.facility(id);
    final m = modifiers(s);
    final total = ResourceBag();
    final lvl = s.facilityLevel(id);
    for (var i = 0; i < n; i++) {
      total.addAll(f.costForLevel(lvl + i, discount: m.costDiscount));
    }
    return total;
  }

  int upgradeFacilityMany(GameState s, String id, int count) {
    var n = 0;
    while (n < count && upgradeFacility(s, id)) {
      n++;
    }
    return n;
  }

  void _pay(GameState s, ResourceBag cost) {
    for (final e in cost.nonZero) {
      s.resources[e.key] = math.max(0.0, s.resources[e.key] - e.value);
    }
  }

  // ----------------------------------------------------------------- robots

  bool isRobotUnlocked(GameState s, RobotConfig r) {
    final p = r.unlock.planet;
    if (p != null && !s.unlockedPlanets.contains(p)) return false;
    final e = r.unlock.entitlement;
    if (e != null && !s.has(e)) return false;
    return true;
  }

  ResourceBag robotCost(GameState s, String id) {
    final r = config.robot(id);
    return r.costForLevel(s.robotLevel(id));
  }

  UpgradeBlock robotBlock(GameState s, String id) {
    final r = config.robot(id);
    if (!isRobotUnlocked(s, r)) return UpgradeBlock.locked;
    if (s.robotLevel(id) >= r.maxLevel) return UpgradeBlock.maxLevel;
    if (!s.resources.covers(robotCost(s, id))) return UpgradeBlock.insufficient;
    return UpgradeBlock.none;
  }

  bool upgradeRobot(GameState s, String id) {
    if (robotBlock(s, id) != UpgradeBlock.none) return false;
    _pay(s, robotCost(s, id));
    s.robots[id] = s.robotLevel(id) + 1;
    s.addStat(Metric.robotUpgrades, 1);
    s.xp += config.player.xpPerRobotUpgrade;
    return true;
  }

  /// Effective bonus of a robot at its current level (e.g. 0.3 = +30%).
  double robotBonus(GameState s, String id) {
    final r = config.robot(id);
    return r.effect.perLevel * s.robotLevel(id) * (1 + robotPower(s));
  }

  // --------------------------------------------------------------- research

  bool isResearchAvailable(GameState s) =>
      s.facilityLevel('research_lab') > 0 || s.resources[ResourceType.research] > 0;

  UpgradeBlock researchBlock(GameState s, String id) {
    final n = config.researchNode(id);
    final lvl = s.researchLevel(id);
    if (lvl >= n.maxLevel) return UpgradeBlock.maxLevel;
    if (s.resources[ResourceType.research] + 1e-9 < n.costForLevel(lvl)) {
      return UpgradeBlock.insufficient;
    }
    return UpgradeBlock.none;
  }

  bool doResearch(GameState s, String id) {
    if (researchBlock(s, id) != UpgradeBlock.none) return false;
    final n = config.researchNode(id);
    s.resources[ResourceType.research] = math.max(
        0.0, s.resources[ResourceType.research] - n.costForLevel(s.researchLevel(id)));
    s.research[id] = s.researchLevel(id) + 1;
    s.addStat(Metric.researchCompleted, 1);
    s.xp += config.player.xpPerResearch;
    return true;
  }

  // ---------------------------------------------------------------- planets

  /// The next locked planet in order, or null when all are unlocked.
  PlanetConfig? nextLockedPlanet(GameState s) {
    for (final p in config.planets) {
      if (!s.unlockedPlanets.contains(p.id)) return p;
    }
    return null;
  }

  bool canUnlockPlanet(GameState s, String id) {
    final next = nextLockedPlanet(s);
    if (next == null || next.id != id) return false;
    return s.resources.covers(next.unlockCost);
  }

  bool unlockPlanet(GameState s, String id) {
    if (!canUnlockPlanet(s, id)) return false;
    final p = config.planet(id);
    _pay(s, p.unlockCost);
    s.unlockedPlanets.add(id);
    s.activePlanet = id;
    s.addStat(Metric.planetsUnlocked, 1);
    s.stats['maxPlanetsUnlocked'] =
        math.max(s.stat('maxPlanetsUnlocked'), s.unlockedPlanets.length.toDouble());
    s.xp += config.player.xpPerPlanet;
    return true;
  }

  bool setActivePlanet(GameState s, String id) {
    if (!s.unlockedPlanets.contains(id)) return false;
    s.activePlanet = id;
    return true;
  }

  // ----------------------------------------------------------- player level

  /// XP needed to go from [level] to [level]+1.
  double xpToNext(int level) =>
      config.player.xpBase * math.pow(level, config.player.xpExponent);

  int playerLevel(GameState s) => levelInfo(s).$1;

  /// (level, xp into current level, xp needed for next level)
  (int, double, double) levelInfo(GameState s) {
    var level = 1;
    var remaining = s.xp;
    while (level < 999) {
      final need = xpToNext(level);
      if (remaining < need) return (level, remaining, need);
      remaining -= need;
      level++;
    }
    return (level, 0, 1);
  }

  // ---------------------------------------------------------------- rewards

  /// Converts a [RewardSpec] into concrete resources at the current rate.
  ResourceBag resolveReward(GameState s, RewardSpec spec, int nowMs) {
    final out = spec.resources.copy();
    if (spec.productionMinutes > 0) {
      final snap = snapshot(s, nowMs: nowMs, boostOverride: 1);
      final secs = spec.productionMinutes * 60;
      for (final r in [ResourceType.ore, ResourceType.energy, ResourceType.alloy]) {
        out[r] += snap.gross[r] * secs;
      }
      // Guarantee a minimum so early-game rewards never show as zero.
      if (out[ResourceType.ore] < 50) out[ResourceType.ore] = 50;
    }
    return out;
  }

  /// Grants a reward. Rewards may exceed the storage cap on purpose.
  ResourceBag grantReward(GameState s, RewardSpec spec, int nowMs) {
    final bag = resolveReward(s, spec, nowMs);
    grantResources(s, bag);
    if (spec.boostMinutes > 0) {
      addBoost(s,
          source: 'ad',
          multiplier: config.adBoost.multiplier,
          minutes: spec.boostMinutes,
          maxStackMinutes: config.adBoost.maxStackMinutes,
          nowMs: nowMs);
    }
    return bag;
  }

  void grantResources(GameState s, ResourceBag bag) {
    for (final e in bag.nonZero) {
      s.resources[e.key] = s.resources[e.key] + e.value;
      if (e.value > 0) {
        s.addStat(Metric.lifetimeFor(e.key), e.value);
        if (e.key == ResourceType.alloy) s.addRunStat(Metric.runAlloy, e.value);
        if (e.key == ResourceType.ore) s.addRunStat(Metric.runOre, e.value);
      }
    }
  }

  // ------------------------------------------------------------ free reward

  Duration freeRewardCooldown(GameState s, int nowMs) {
    final readyAt =
        s.lastFreeRewardMs + (config.freeRewardCooldownMinutes * 60000).round();
    return nowMs >= readyAt ? Duration.zero : Duration(milliseconds: readyAt - nowMs);
  }

  ResourceBag claimFreeReward(GameState s, int nowMs) {
    if (freeRewardCooldown(s, nowMs) > Duration.zero) return ResourceBag();
    s.lastFreeRewardMs = nowMs;
    return grantReward(
        s,
        RewardSpec.fromJson({'productionMinutes': config.freeRewardProductionMinutes}),
        nowMs);
  }

  // -------------------------------------------------------------- purchases

  /// Applies a purchased product. Idempotent per [transactionId].
  bool applyPurchase(GameState s, ProductConfig p, String transactionId, int nowMs) {
    if (transactionId.isNotEmpty && s.processedPurchaseIds.contains(transactionId)) {
      return false;
    }
    final ent = p.grantEntitlement;
    if (p.kind == ProductKind.nonConsumable && ent != null && s.has(ent)) {
      // Already owned (e.g. restore): make sure nothing is granted twice.
      if (transactionId.isNotEmpty) s.processedPurchaseIds.add(transactionId);
      return false;
    }
    if (ent != null) s.entitlements.add(ent);
    grantResources(s, p.grantResources);
    final b = p.grantBoost;
    if (b != null) {
      addBoost(s, source: 'iap', multiplier: b.multiplier, minutes: b.minutes, nowMs: nowMs);
    }
    if (ent == 'starter_pack') {
      // Starter robot arrives already hired.
      s.robots['pioneer_bot'] = math.max(1, s.robotLevel('pioneer_bot'));
    }
    if (transactionId.isNotEmpty) s.processedPurchaseIds.add(transactionId);
    return true;
  }

  bool noAds(GameState s) => config.shop.noAdsEntitlements.any(s.has);
  bool skipsRewardedAds(GameState s) =>
      config.shop.rewardedSkipEntitlements.any(s.has);
}
