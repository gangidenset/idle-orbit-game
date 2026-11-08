import 'resources.dart';

/// Names of tracked counters. Missions and achievements refer to these by
/// string in balance.json, so keep them stable.
abstract final class Metric {
  static const lifetimeOre = 'lifetimeOre';
  static const lifetimeEnergy = 'lifetimeEnergy';
  static const lifetimeAlloy = 'lifetimeAlloy';
  static const lifetimeResearch = 'lifetimeResearch';
  static const runOre = 'runOre';
  static const runAlloy = 'runAlloy';
  static const facilityUpgrades = 'facilityUpgrades';
  static const robotUpgrades = 'robotUpgrades';
  static const researchCompleted = 'researchCompleted';
  static const planetsUnlocked = 'planetsUnlocked';
  static const prestigeCount = 'prestigeCount';
  static const offlineClaims = 'offlineClaims';
  static const adsWatched = 'adsWatched';
  static const sessions = 'sessions';
  static const playSeconds = 'playSeconds';

  /// Ore mined while actively playing, measured in "minutes of production".
  /// Normalised so daily missions stay meaningful at every stage of the game.
  static const oreMinutes = 'oreMinutes';

  static String lifetimeFor(ResourceType r) => switch (r) {
        ResourceType.ore => lifetimeOre,
        ResourceType.energy => lifetimeEnergy,
        ResourceType.alloy => lifetimeAlloy,
        ResourceType.research => lifetimeResearch,
      };
}

class Boost {
  Boost({required this.multiplier, required this.endMs, required this.source});

  final double multiplier;
  final int endMs;
  final String source; // 'ad' | 'iap' | 'reward'

  bool activeAt(int nowMs) => nowMs < endMs;

  Map<String, dynamic> toJson() =>
      {'multiplier': multiplier, 'endMs': endMs, 'source': source};

  factory Boost.fromJson(Map<String, dynamic> j) => Boost(
        multiplier: (j['multiplier'] as num).toDouble(),
        endMs: (j['endMs'] as num).toInt(),
        source: j['source'] as String? ?? 'ad',
      );
}

/// A computed but not yet claimed offline reward. Persisted so that killing
/// the app on the reward screen neither loses nor duplicates it.
class OfflineReward {
  OfflineReward({
    required this.elapsedSeconds,
    required this.creditedSeconds,
    required this.gained,
    required this.capped,
    required this.clockAnomaly,
  });

  /// Real time away (after anti-cheat checks).
  final int elapsedSeconds;

  /// Seconds actually credited (after cap).
  final int creditedSeconds;
  final ResourceBag gained;
  final bool capped;

  /// True when the device clock appeared to move backwards.
  final bool clockAnomaly;

  Map<String, dynamic> toJson() => {
        'elapsedSeconds': elapsedSeconds,
        'creditedSeconds': creditedSeconds,
        'gained': gained.toJson(),
        'capped': capped,
        'clockAnomaly': clockAnomaly,
      };

  factory OfflineReward.fromJson(Map<String, dynamic> j) => OfflineReward(
        elapsedSeconds: (j['elapsedSeconds'] as num).toInt(),
        creditedSeconds: (j['creditedSeconds'] as num).toInt(),
        gained: ResourceBag.fromJson(Map<String, dynamic>.from(j['gained'] as Map)),
        capped: j['capped'] as bool? ?? false,
        clockAnomaly: j['clockAnomaly'] as bool? ?? false,
      );
}

class DailyState {
  DailyState({
    this.dateKey = '',
    Map<String, double>? startStats,
    List<String>? missionIds,
    Set<String>? claimedMissions,
    this.loginClaimedDateKey = '',
    this.loginDayIndex = 0,
  })  : startStats = startStats ?? {},
        missionIds = missionIds ?? [],
        claimedMissions = claimedMissions ?? {};

  /// Local calendar day "yyyy-MM-dd" the missions belong to.
  String dateKey;

  /// Snapshot of lifetime counters at the start of [dateKey].
  Map<String, double> startStats;
  List<String> missionIds;
  Set<String> claimedMissions;
  String loginClaimedDateKey;

  /// Index into the login reward cycle for the next claim.
  int loginDayIndex;

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'startStats': startStats,
        'missionIds': missionIds,
        'claimedMissions': claimedMissions.toList(),
        'loginClaimedDateKey': loginClaimedDateKey,
        'loginDayIndex': loginDayIndex,
      };

  factory DailyState.fromJson(Map<String, dynamic> j) => DailyState(
        dateKey: j['dateKey'] as String? ?? '',
        startStats: _doubleMap(j['startStats']),
        missionIds: ((j['missionIds'] as List?) ?? const []).cast<String>().toList(),
        claimedMissions:
            ((j['claimedMissions'] as List?) ?? const []).cast<String>().toSet(),
        loginClaimedDateKey: j['loginClaimedDateKey'] as String? ?? '',
        loginDayIndex: (j['loginDayIndex'] as num?)?.toInt() ?? 0,
      );
}

class Settings {
  Settings({
    this.adFrequency = 'standard',
    this.haptics = true,
    this.analyticsConsent = true,
  });

  String adFrequency;
  bool haptics;
  bool analyticsConsent;

  Map<String, dynamic> toJson() => {
        'adFrequency': adFrequency,
        'haptics': haptics,
        'analyticsConsent': analyticsConsent,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        adFrequency: j['adFrequency'] as String? ?? 'standard',
        haptics: j['haptics'] as bool? ?? true,
        analyticsConsent: j['analyticsConsent'] as bool? ?? true,
      );
}

Map<String, double> _doubleMap(Object? v) => v == null
    ? {}
    : (v as Map).map((k, x) => MapEntry(k as String, (x as num).toDouble()));
Map<String, int> _intMap(Object? v) => v == null
    ? {}
    : (v as Map).map((k, x) => MapEntry(k as String, (x as num).toInt()));

/// The complete persisted game state.
///
/// Split into "run" data (reset by prestige) and "meta" data (kept forever).
class GameState {
  GameState({
    required this.createdAtMs,
    required this.lastSeenMs,
    required this.highWaterMs,
    required this.resources,
    required this.facilities,
    required this.robots,
    required this.unlockedPlanets,
    required this.activePlanet,
    required this.research,
    this.prestigePoints = 0,
    Map<String, int>? prestigeUpgrades,
    Map<String, double>? stats,
    Map<String, double>? runStats,
    DailyState? daily,
    Set<String>? claimedAchievements,
    List<Boost>? boosts,
    this.xp = 0,
    this.pendingOfflineReward,
    this.lastFreeRewardMs = 0,
    Set<String>? entitlements,
    Set<String>? processedPurchaseIds,
    Settings? settings,
    this.firstSessionDateKey = '',
  })  : prestigeUpgrades = prestigeUpgrades ?? {},
        stats = stats ?? {},
        runStats = runStats ?? {},
        daily = daily ?? DailyState(),
        claimedAchievements = claimedAchievements ?? {},
        boosts = boosts ?? [],
        entitlements = entitlements ?? {},
        processedPurchaseIds = processedPurchaseIds ?? {},
        settings = settings ?? Settings();

  // ---- meta ----
  final int createdAtMs;

  /// Wall clock of the last save while the game was running.
  int lastSeenMs;

  /// Highest wall clock value ever observed. Used to detect clock rollback.
  int highWaterMs;

  // ---- run (reset on prestige) ----
  ResourceBag resources;
  Map<String, int> facilities;
  Map<String, int> robots;
  Set<String> unlockedPlanets;
  String activePlanet;
  Map<String, int> research;
  Map<String, double> runStats;

  // ---- meta (persist across prestige) ----
  double prestigePoints;
  Map<String, int> prestigeUpgrades;
  Map<String, double> stats;
  DailyState daily;
  Set<String> claimedAchievements;
  List<Boost> boosts;
  double xp;
  OfflineReward? pendingOfflineReward;
  int lastFreeRewardMs;
  Set<String> entitlements;

  /// Store transaction ids already granted, to make grants idempotent.
  Set<String> processedPurchaseIds;
  Settings settings;
  String firstSessionDateKey;

  double stat(String key) => stats[key] ?? 0;
  void addStat(String key, double v) => stats[key] = stat(key) + v;
  double runStat(String key) => runStats[key] ?? 0;
  void addRunStat(String key, double v) => runStats[key] = runStat(key) + v;

  int facilityLevel(String id) => facilities[id] ?? 0;
  int robotLevel(String id) => robots[id] ?? 0;
  int researchLevel(String id) => research[id] ?? 0;
  int prestigeLevel(String id) => prestigeUpgrades[id] ?? 0;
  bool has(String entitlement) => entitlements.contains(entitlement);

  Map<String, dynamic> toJson() => {
        'createdAtMs': createdAtMs,
        'lastSeenMs': lastSeenMs,
        'highWaterMs': highWaterMs,
        'resources': resources.toJson(),
        'facilities': facilities,
        'robots': robots,
        'unlockedPlanets': unlockedPlanets.toList(),
        'activePlanet': activePlanet,
        'research': research,
        'runStats': runStats,
        'prestigePoints': prestigePoints,
        'prestigeUpgrades': prestigeUpgrades,
        'stats': stats,
        'daily': daily.toJson(),
        'claimedAchievements': claimedAchievements.toList(),
        'boosts': boosts.map((b) => b.toJson()).toList(),
        'xp': xp,
        'pendingOfflineReward': pendingOfflineReward?.toJson(),
        'lastFreeRewardMs': lastFreeRewardMs,
        'entitlements': entitlements.toList(),
        'processedPurchaseIds': processedPurchaseIds.toList(),
        'settings': settings.toJson(),
        'firstSessionDateKey': firstSessionDateKey,
      };

  factory GameState.fromJson(Map<String, dynamic> j) => GameState(
        createdAtMs: (j['createdAtMs'] as num).toInt(),
        lastSeenMs: (j['lastSeenMs'] as num).toInt(),
        highWaterMs: (j['highWaterMs'] as num?)?.toInt() ??
            (j['lastSeenMs'] as num).toInt(),
        resources: ResourceBag.fromJson(
            Map<String, dynamic>.from(j['resources'] as Map? ?? {})),
        facilities: _intMap(j['facilities']),
        robots: _intMap(j['robots']),
        unlockedPlanets:
            ((j['unlockedPlanets'] as List?) ?? const []).cast<String>().toSet(),
        activePlanet: j['activePlanet'] as String,
        research: _intMap(j['research']),
        runStats: _doubleMap(j['runStats']),
        prestigePoints: (j['prestigePoints'] as num?)?.toDouble() ?? 0,
        prestigeUpgrades: _intMap(j['prestigeUpgrades']),
        stats: _doubleMap(j['stats']),
        daily: j['daily'] == null
            ? DailyState()
            : DailyState.fromJson(Map<String, dynamic>.from(j['daily'] as Map)),
        claimedAchievements:
            ((j['claimedAchievements'] as List?) ?? const []).cast<String>().toSet(),
        boosts: ((j['boosts'] as List?) ?? const [])
            .map((e) => Boost.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        xp: (j['xp'] as num?)?.toDouble() ?? 0,
        pendingOfflineReward: j['pendingOfflineReward'] == null
            ? null
            : OfflineReward.fromJson(
                Map<String, dynamic>.from(j['pendingOfflineReward'] as Map)),
        lastFreeRewardMs: (j['lastFreeRewardMs'] as num?)?.toInt() ?? 0,
        entitlements:
            ((j['entitlements'] as List?) ?? const []).cast<String>().toSet(),
        processedPurchaseIds: ((j['processedPurchaseIds'] as List?) ?? const [])
            .cast<String>()
            .toSet(),
        settings: j['settings'] == null
            ? Settings()
            : Settings.fromJson(Map<String, dynamic>.from(j['settings'] as Map)),
        firstSessionDateKey: j['firstSessionDateKey'] as String? ?? '',
      );
}
