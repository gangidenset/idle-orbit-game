import 'dart:convert';

import '../model/resources.dart';

/// All balance numbers live in `assets/config/balance.json` and are parsed
/// into these typed classes. Game logic must never hardcode balance values.

double _d(Object? v, [double fallback = 0]) =>
    v == null ? fallback : (v as num).toDouble();
int _i(Object? v, [int fallback = 0]) => v == null ? fallback : (v as num).toInt();
Map<String, dynamic> _m(Object? v) =>
    v == null ? <String, dynamic>{} : Map<String, dynamic>.from(v as Map);
List<Map<String, dynamic>> _l(Object? v) => v == null
    ? const []
    : (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

enum EffectType {
  production,
  offlineEfficiency,
  offlineCapHours,
  costReduction,
  storageCap,
  robotPower,
  startingResources;

  static EffectType parse(String s) => EffectType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => throw FormatException('Unknown effect type "$s"'),
      );
}

/// An effect applied per level. `resource == null` means "all".
class Effect {
  const Effect(this.type, this.resource, this.perLevel);

  final EffectType type;
  final ResourceType? resource;
  final double perLevel;

  factory Effect.fromJson(Map<String, dynamic> j) {
    final res = j['resource'] as String? ?? 'all';
    return Effect(
      EffectType.parse(j['type'] as String),
      res == 'all' ? null : (ResourceType.tryParse(res) ??
          (throw FormatException('Unknown resource "$res"'))),
      _d(j['perLevel']),
    );
  }

  bool appliesTo(ResourceType r) => resource == null || resource == r;
}

/// Something that can be levelled with exponentially growing cost.
mixin Levelled {
  ResourceBag get baseCost;
  double get costGrowth;

  ResourceBag costForLevel(int currentLevel, {double discount = 0}) {
    final f = _pow(costGrowth, currentLevel) * (1 - discount);
    return baseCost.scaled(f);
  }
}

double _pow(double b, int e) {
  var r = 1.0;
  for (var i = 0; i < e; i++) {
    r *= b;
  }
  return r;
}

class OfflineConfig {
  OfflineConfig.fromJson(Map<String, dynamic> j)
      : baseCapHours = _d(j['baseCapHours'], 8),
        baseEfficiency = _d(j['baseEfficiency'], 1),
        minSecondsForReward = _i(j['minSecondsForReward'], 60),
        simStepSeconds = _d(j['simStepSeconds'], 60),
        adMultiplier = _d(j['adMultiplier'], 2);

  final double baseCapHours;
  final double baseEfficiency;
  final int minSecondsForReward;
  final double simStepSeconds;
  final double adMultiplier;
}

class PlayerConfig {
  PlayerConfig.fromJson(Map<String, dynamic> j)
      : xpPerFacilityUpgrade = _d(j['xpPerFacilityUpgrade'], 1),
        xpPerRobotUpgrade = _d(j['xpPerRobotUpgrade'], 2),
        xpPerResearch = _d(j['xpPerResearch'], 3),
        xpPerPlanet = _d(j['xpPerPlanet'], 25),
        xpBase = _d(j['xpBase'], 10),
        xpExponent = _d(j['xpExponent'], 1.5),
        productionBonusPerLevel = _d(j['productionBonusPerLevel'], 0.01);

  final double xpPerFacilityUpgrade;
  final double xpPerRobotUpgrade;
  final double xpPerResearch;
  final double xpPerPlanet;
  final double xpBase;
  final double xpExponent;
  final double productionBonusPerLevel;
}

class Milestone {
  Milestone.fromJson(Map<String, dynamic> j)
      : level = _i(j['level']),
        multiplier = _d(j['multiplier'], 1);
  final int level;
  final double multiplier;
}

class StorageConfig {
  StorageConfig.fromJson(Map<String, dynamic> j)
      : facilityId = j['facilityId'] as String,
        baseCap = ResourceBag.fromJson(_m(j['baseCap'])),
        capGrowthPerLevel = _d(j['capGrowthPerLevel'], 1.5);

  final String facilityId;
  final ResourceBag baseCap;
  final double capGrowthPerLevel;
}

class FacilityConfig with Levelled {
  FacilityConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        icon = j['icon'] as String? ?? j['id'] as String,
        startLevel = _i(j['startLevel']),
        produces = ResourceBag.fromJson(_m(j['produces'])),
        consumes = ResourceBag.fromJson(_m(j['consumes'])),
        baseCost = ResourceBag.fromJson(_m(j['baseCost'])),
        costGrowth = _d(j['costGrowth'], 1.15),
        requires = _m(j['requires']).map((k, v) => MapEntry(k, _i(v))),
        tierNames = ((j['tierNames'] as List?) ?? const []).cast<String>();

  final String id;
  final String name;
  final String description;
  final String icon;
  final int startLevel;
  final ResourceBag produces;
  final ResourceBag consumes;
  @override
  final ResourceBag baseCost;
  @override
  final double costGrowth;

  /// Other facility id -> minimum level before this one can be built.
  final Map<String, int> requires;

  /// Display name for each visual tier (see [VisualsConfig.tierLevels]).
  final List<String> tierNames;

  bool get isConverter => !consumes.isEmpty;
}

class UnlockRule {
  UnlockRule.fromJson(Map<String, dynamic> j)
      : planet = j['planet'] as String?,
        entitlement = j['entitlement'] as String?;
  final String? planet;
  final String? entitlement;
}

class RobotConfig with Levelled {
  RobotConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        special = j['special'] as bool? ?? false,
        effect = Effect.fromJson(_m(j['effect'])),
        baseCost = ResourceBag.fromJson(_m(j['baseCost'])),
        costGrowth = _d(j['costGrowth'], 1.3),
        maxLevel = _i(j['maxLevel'], 100),
        unlock = UnlockRule.fromJson(_m(j['unlock']));

  final String id;
  final String name;
  final String description;
  final bool special;
  final Effect effect;
  @override
  final ResourceBag baseCost;
  @override
  final double costGrowth;
  final int maxLevel;
  final UnlockRule unlock;
}

class PlanetConfig {
  PlanetConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        colorHex = j['color'] as String? ?? '#4FA3E0',
        permanentMultiplier = _d(j['permanentMultiplier'], 1),
        activeBonus = _m(j['activeBonus']).map(
            (k, v) => MapEntry(ResourceType.tryParse(k)!, _d(v, 1))),
        unlockCost = ResourceBag.fromJson(_m(j['unlockCost']));

  final String id;
  final String name;
  final String description;
  final String colorHex;
  final double permanentMultiplier;
  final Map<ResourceType, double> activeBonus;
  final ResourceBag unlockCost;

  int get colorValue =>
      int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16);
}

/// Research node and prestige upgrades share the same shape.
class UpgradeConfig {
  UpgradeConfig.fromJson(Map<String, dynamic> j, {String costKey = 'research'})
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        effect = Effect.fromJson(_m(j['effect'])),
        baseCostAmount = _d(_m(j['baseCost'])[costKey]),
        costGrowth = _d(j['costGrowth'], 1.5),
        maxLevel = _i(j['maxLevel'], 10),
        grantsPerLevel = ResourceBag.fromJson(_m(j['grantsPerLevel']));

  final String id;
  final String name;
  final String description;
  final Effect effect;
  final ResourceBag grantsPerLevel;
  final double baseCostAmount;
  final double costGrowth;
  final int maxLevel;

  double costForLevel(int level) => baseCostAmount * _pow(costGrowth, level);
}

class PrestigeConfig {
  PrestigeConfig.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String? ?? '転生',
        requiredPlanet = j['requiredPlanet'] as String,
        metric = j['metric'] as String? ?? 'runAlloy',
        pointsDivisor = _d(j['pointsDivisor'], 1000),
        pointsExponent = _d(j['pointsExponent'], 0.5),
        productionPerEarnedPoint = _d(j['productionPerEarnedPoint']),
        upgrades = _l(j['upgrades'])
            .map((e) => UpgradeConfig.fromJson(e, costKey: 'prestige'))
            .toList();

  final String name;
  final String requiredPlanet;
  final String metric;
  final double pointsDivisor;
  final double pointsExponent;

  /// Passive production bonus per warp point ever earned (spent or not).
  final double productionPerEarnedPoint;
  final List<UpgradeConfig> upgrades;
}

class BoostConfig {
  BoostConfig.fromJson(Map<String, dynamic> j)
      : multiplier = _d(j['multiplier'], 2),
        minutes = _d(j['minutes'], 30),
        maxStackMinutes = _d(j['maxStackMinutes'], 240);
  final double multiplier;
  final double minutes;
  final double maxStackMinutes;
}

class InterstitialConfig {
  InterstitialConfig.fromJson(Map<String, dynamic> j)
      : frequencies = _m(j['frequencies']).map((k, v) => MapEntry(k, _i(v))),
        defaultFrequency = j['defaultFrequency'] as String? ?? 'standard',
        firstAfterSessionSeconds = _i(j['firstAfterSessionSeconds'], 180),
        maxPerSession = _i(j['maxPerSession'], 4),
        cooldownAfterRewardedSeconds = _i(j['cooldownAfterRewardedSeconds'], 120);

  /// Frequency preset name -> minimum interval in seconds.
  final Map<String, int> frequencies;
  final String defaultFrequency;
  final int firstAfterSessionSeconds;
  final int maxPerSession;
  final int cooldownAfterRewardedSeconds;
}

/// Generic reward description used by login rewards, missions, etc.
class RewardSpec {
  RewardSpec.fromJson(Map<String, dynamic> j)
      : resources = ResourceBag.fromJson({
          for (final e in j.entries)
            if (ResourceType.tryParse(e.key) != null) e.key: e.value,
        }),
        productionMinutes = _d(j['productionMinutes']),
        boostMinutes = _d(j['boostMinutes']);

  final ResourceBag resources;

  /// Grants N minutes worth of the current production rate (ore/energy/alloy).
  final double productionMinutes;

  /// Grants an ad-equivalent production boost for N minutes.
  final double boostMinutes;
}

class LoginRewardConfig {
  LoginRewardConfig.fromJson(Map<String, dynamic> j)
      : day = _i(j['day']),
        reward = RewardSpec.fromJson(_m(j['reward']));
  final int day;
  final RewardSpec reward;
}

class MissionConfig {
  MissionConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        metric = j['metric'] as String,
        target = _d(j['target'], 1),
        reward = RewardSpec.fromJson(_m(j['reward']));
  final String id;
  final String name;
  final String metric;
  final double target;
  final RewardSpec reward;
}

class AchievementConfig {
  AchievementConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        metric = j['metric'] as String,
        target = _d(j['target'], 1),
        productionBonus = _d(j['productionBonus']);
  final String id;
  final String name;
  final String description;
  final String metric;
  final double target;
  final double productionBonus;
}

enum ProductKind { consumable, nonConsumable }

class ProductConfig {
  ProductConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        kind = (j['type'] as String) == 'consumable'
            ? ProductKind.consumable
            : ProductKind.nonConsumable,
        storeIds = _m(j['storeIds']).map((k, v) => MapEntry(k, v as String)),
        placeholderPriceJpy = _i(j['placeholderPriceJpy']),
        grantEntitlement = _m(j['grants'])['entitlement'] as String?,
        grantResources = ResourceBag.fromJson(_m(_m(j['grants'])['resources'])),
        grantBoost = _m(j['grants'])['boost'] == null
            ? null
            : BoostConfig.fromJson(_m(_m(j['grants'])['boost']));

  final String id;
  final String name;
  final String description;
  final ProductKind kind;

  /// Platform ("android"/"ios") -> store product id.
  final Map<String, String> storeIds;

  /// Reference price only. Real prices always come from the store.
  final int placeholderPriceJpy;
  final String? grantEntitlement;
  final ResourceBag grantResources;
  final BoostConfig? grantBoost;
}

class ShopConfig {
  ShopConfig.fromJson(Map<String, dynamic> j)
      : products = _l(j['products']).map(ProductConfig.fromJson).toList(),
        premiumProductionBonus = _d(_m(j['premium'])['productionBonus']),
        premiumOfflineCapHours = _d(_m(j['premium'])['offlineCapHours']),
        rewardedSkipEntitlements =
            ((j['rewardedSkipEntitlements'] as List?) ?? const []).cast<String>(),
        noAdsEntitlements =
            ((j['noAdsEntitlements'] as List?) ?? const ['no_ads']).cast<String>();

  final List<ProductConfig> products;
  final double premiumProductionBonus;
  final double premiumOfflineCapHours;
  final List<String> rewardedSkipEntitlements;
  final List<String> noAdsEntitlements;

  ProductConfig? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class DecorationConfig {
  DecorationConfig.fromJson(Map<String, dynamic> j)
      : id = j['id'] as String,
        name = j['name'] as String,
        description = j['description'] as String? ?? '',
        metric = _m(j['condition'])['metric'] as String,
        value = _d(_m(j['condition'])['value'], 1);
  final String id;
  final String name;
  final String description;
  final String metric;
  final double value;
}

class VisualsConfig {
  VisualsConfig.fromJson(Map<String, dynamic> j)
      : tierLevels = ((j['tierLevels'] as List?) ?? const [1]).map((e) => _i(e)).toList(),
        decorations = _l(j['decorations']).map(DecorationConfig.fromJson).toList();

  /// Facility level at which each visual tier starts (ascending).
  final List<int> tierLevels;
  final List<DecorationConfig> decorations;
}

class BalanceConfig {
  BalanceConfig.fromJson(Map<String, dynamic> j)
      : configVersion = _i(j['configVersion'], 1),
        tickSeconds = _d(j['tickSeconds'], 0.25),
        autosaveSeconds = _d(j['autosaveSeconds'], 15),
        startingResources = ResourceBag.fromJson(_m(j['startingResources'])),
        offline = OfflineConfig.fromJson(_m(j['offline'])),
        player = PlayerConfig.fromJson(_m(j['player'])),
        visuals = VisualsConfig.fromJson(_m(j['visuals'])),
        milestones = _l(j['milestones']).map(Milestone.fromJson).toList()
          ..sort((a, b) => a.level.compareTo(b.level)),
        storage = StorageConfig.fromJson(_m(j['storage'])),
        facilities = _l(j['facilities']).map(FacilityConfig.fromJson).toList(),
        robots = _l(j['robots']).map(RobotConfig.fromJson).toList(),
        planets = _l(j['planets']).map(PlanetConfig.fromJson).toList(),
        research = _l(j['research']).map((e) => UpgradeConfig.fromJson(e)).toList(),
        prestige = PrestigeConfig.fromJson(_m(j['prestige'])),
        adBoost = BoostConfig.fromJson(_m(_m(j['boosts'])['ad'])),
        freeRewardCooldownMinutes = _d(_m(j['freeReward'])['cooldownMinutes'], 30),
        freeRewardProductionMinutes =
            _d(_m(j['freeReward'])['productionMinutes'], 20),
        interstitial =
            InterstitialConfig.fromJson(_m(_m(j['ads'])['interstitial'])),
        loginRewards =
            _l(j['loginRewards']).map(LoginRewardConfig.fromJson).toList(),
        dailyMissionCount = _i(_m(j['missions'])['dailyCount'], 3),
        missionPool =
            _l(_m(j['missions'])['pool']).map(MissionConfig.fromJson).toList(),
        achievements =
            _l(j['achievements']).map(AchievementConfig.fromJson).toList(),
        shop = ShopConfig.fromJson(_m(j['shop'])) {
    _validate();
  }

  factory BalanceConfig.fromJsonString(String s) =>
      BalanceConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  final int configVersion;
  final double tickSeconds;
  final double autosaveSeconds;
  final ResourceBag startingResources;
  final OfflineConfig offline;
  final PlayerConfig player;
  final VisualsConfig visuals;
  final List<Milestone> milestones;
  final StorageConfig storage;
  final List<FacilityConfig> facilities;
  final List<RobotConfig> robots;
  final List<PlanetConfig> planets;
  final List<UpgradeConfig> research;
  final PrestigeConfig prestige;
  final BoostConfig adBoost;
  final double freeRewardCooldownMinutes;
  final double freeRewardProductionMinutes;
  final InterstitialConfig interstitial;
  final List<LoginRewardConfig> loginRewards;
  final int dailyMissionCount;
  final List<MissionConfig> missionPool;
  final List<AchievementConfig> achievements;
  final ShopConfig shop;

  FacilityConfig facility(String id) => facilities.firstWhere((f) => f.id == id);
  RobotConfig robot(String id) => robots.firstWhere((r) => r.id == id);
  PlanetConfig planet(String id) => planets.firstWhere((p) => p.id == id);
  UpgradeConfig researchNode(String id) => research.firstWhere((r) => r.id == id);
  UpgradeConfig prestigeUpgrade(String id) =>
      prestige.upgrades.firstWhere((r) => r.id == id);
  int planetIndex(String id) => planets.indexWhere((p) => p.id == id);

  void _validate() {
    void unique(Iterable<String> ids, String what) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) throw FormatException('Duplicate $what id "$id"');
      }
    }

    unique(facilities.map((f) => f.id), 'facility');
    unique(robots.map((f) => f.id), 'robot');
    unique(planets.map((f) => f.id), 'planet');
    unique(research.map((f) => f.id), 'research');
    unique(missionPool.map((f) => f.id), 'mission');
    unique(achievements.map((f) => f.id), 'achievement');
    if (planets.isEmpty) throw const FormatException('No planets defined');
    if (!facilities.any((f) => f.id == storage.facilityId)) {
      throw FormatException('Storage facility "${storage.facilityId}" missing');
    }
    if (planetIndex(prestige.requiredPlanet) < 0) {
      throw FormatException('Unknown prestige planet ${prestige.requiredPlanet}');
    }
    for (final f in facilities) {
      for (final req in f.requires.keys) {
        if (!facilities.any((x) => x.id == req)) {
          throw FormatException('Facility ${f.id} requires unknown $req');
        }
      }
    }
    for (final r in robots) {
      final p = r.unlock.planet;
      if (p != null && planetIndex(p) < 0) {
        throw FormatException('Robot ${r.id} unlocks on unknown planet $p');
      }
    }
    for (final f in facilities) {
      if (f.tierNames.isNotEmpty && f.tierNames.length != visuals.tierLevels.length) {
        throw FormatException('Facility ${f.id} needs ${visuals.tierLevels.length} tierNames');
      }
    }
    unique(visuals.decorations.map((d) => d.id), 'decoration');
    if (dailyMissionCount > missionPool.length) {
      throw const FormatException('dailyCount exceeds mission pool size');
    }
  }
}
