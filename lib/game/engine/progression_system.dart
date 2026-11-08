import 'dart:math' as math;

import '../config/balance_config.dart';
import '../model/game_state.dart';
import '../model/resources.dart';
import 'game_engine.dart';

class MissionProgress {
  MissionProgress(this.config, this.progress, this.claimed);
  final MissionConfig config;
  final double progress;
  final bool claimed;
  bool get complete => progress >= config.target;
  double get ratio => (progress / config.target).clamp(0.0, 1.0);
}

class AchievementProgress {
  AchievementProgress(this.config, this.value, this.claimed);
  final AchievementConfig config;
  final double value;
  final bool claimed;
  bool get complete => value >= config.target;
  double get ratio => (value / config.target).clamp(0.0, 1.0);
}

/// Daily login rewards, daily missions and achievements.
class ProgressionSystem {
  ProgressionSystem(this.engine);

  final GameEngine engine;
  BalanceConfig get config => engine.config;

  static String dateKeyOf(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  /// Rolls daily state forward to [dateKey]. Never rolls backwards, so
  /// setting the clock back cannot re-open yesterday's rewards.
  /// Returns true when a new day started.
  bool ensureDaily(GameState s, String dateKey) {
    final d = s.daily;
    if (d.dateKey.isNotEmpty && dateKey.compareTo(d.dateKey) <= 0) return false;
    d.dateKey = dateKey;
    d.startStats = Map.of(s.stats);
    d.claimedMissions.clear();
    d.missionIds = _pickMissions(s, dateKey);
    return true;
  }

  List<String> _pickMissions(GameState s, String dateKey) {
    final seed = dateKey.codeUnits.fold<int>(s.createdAtMs & 0x7fffffff,
        (a, c) => (a * 31 + c) & 0x7fffffff);
    final pool = config.missionPool.map((m) => m.id).toList()..shuffle(math.Random(seed));
    return pool.take(config.dailyMissionCount).toList();
  }

  List<MissionProgress> missions(GameState s) {
    return [
      for (final id in s.daily.missionIds)
        if (config.missionPool.any((m) => m.id == id))
          _missionProgress(s, config.missionPool.firstWhere((m) => m.id == id)),
    ];
  }

  MissionProgress _missionProgress(GameState s, MissionConfig m) {
    final start = s.daily.startStats[m.metric] ?? 0;
    return MissionProgress(
        m, math.max(0.0, s.stat(m.metric) - start), s.daily.claimedMissions.contains(m.id));
  }

  ResourceBag? claimMission(GameState s, String id, int nowMs) {
    final mp = missions(s).where((m) => m.config.id == id).firstOrNull;
    if (mp == null || mp.claimed || !mp.complete) return null;
    s.daily.claimedMissions.add(id);
    return engine.grantReward(s, mp.config.reward, nowMs);
  }

  int claimableMissionCount(GameState s) =>
      missions(s).where((m) => m.complete && !m.claimed).length;

  // ------------------------------------------------------------- login

  bool canClaimLogin(GameState s) =>
      s.daily.dateKey.isNotEmpty && s.daily.loginClaimedDateKey != s.daily.dateKey;

  LoginRewardConfig nextLoginReward(GameState s) =>
      config.loginRewards[s.daily.loginDayIndex % config.loginRewards.length];

  ResourceBag? claimLogin(GameState s, int nowMs) {
    if (!canClaimLogin(s)) return null;
    final r = nextLoginReward(s);
    s.daily.loginClaimedDateKey = s.daily.dateKey;
    s.daily.loginDayIndex++;
    return engine.grantReward(s, r.reward, nowMs);
  }

  // ------------------------------------------------------- achievements

  double metricValue(GameState s, String metric) => switch (metric) {
        Metric.planetsUnlocked => math.max(
            s.stat('maxPlanetsUnlocked'), s.unlockedPlanets.length.toDouble()),
        _ => s.stat(metric),
      };

  List<AchievementProgress> achievements(GameState s) => [
        for (final a in config.achievements)
          AchievementProgress(
              a, metricValue(s, a.metric), s.claimedAchievements.contains(a.id)),
      ];

  bool claimAchievement(GameState s, String id) {
    final a = achievements(s).where((x) => x.config.id == id).firstOrNull;
    if (a == null || a.claimed || !a.complete) return false;
    s.claimedAchievements.add(id);
    return true;
  }

  int claimableAchievementCount(GameState s) =>
      achievements(s).where((a) => a.complete && !a.claimed).length;
}
