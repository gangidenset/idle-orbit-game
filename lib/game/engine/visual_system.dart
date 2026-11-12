import 'dart:math' as math;

import '../config/balance_config.dart';
import '../model/game_state.dart';
import 'game_engine.dart';

/// A facility reached a new visual tier.
class Evolution {
  const Evolution(this.facility, this.tier, this.name);
  final FacilityConfig facility;

  /// 1-based tier.
  final int tier;
  final String name;
}

/// Snapshot of what the base looks like, used to detect changes.
class BaseLook {
  const BaseLook(this.tiers, this.decorations, [this.monuments = const {}]);
  final Map<String, int> tiers;
  final Set<String> decorations;

  /// Planet ids whose monument stands.
  final Set<String> monuments;
}

/// How the base *looks*: facility tiers and unlocked decorations.
/// Pure logic, driven entirely by balance.json.
class VisualSystem {
  VisualSystem(this.engine);

  final GameEngine engine;
  BalanceConfig get config => engine.config;
  List<int> get _levels => config.visuals.tierLevels;

  /// 0 = not built; 1..N = visual tier.
  int tierFor(int level) {
    var t = 0;
    for (final l in _levels) {
      if (level >= l) t++;
    }
    return t;
  }

  int maxTier() => _levels.length;

  String tierName(FacilityConfig f, int level) {
    final t = tierFor(level);
    if (t == 0 || f.tierNames.isEmpty) return f.name;
    return f.tierNames[t - 1];
  }

  /// Level at which the next tier starts, or null at the top tier.
  int? nextTierLevel(int level) {
    for (final l in _levels) {
      if (l > level) return l;
    }
    return null;
  }

  double metric(GameState s, String name) => switch (name) {
        'playerLevel' => engine.playerLevel(s).toDouble(),
        'robotsHired' => s.robots.values.where((l) => l > 0).length.toDouble(),
        'researchLevels' => s.research.values.fold<int>(0, (a, b) => a + b).toDouble(),
        'planetsUnlocked' => s.unlockedPlanets.length.toDouble(),
        'prestigeCount' => s.stat(Metric.prestigeCount),
        'premium' => engine.hasPremium(s) ? 1 : 0,
        _ => s.stat(name),
      };

  List<DecorationConfig> activeDecorations(GameState s) => [
        for (final d in config.visuals.decorations)
          if (metric(s, d.metric) >= d.value) d,
      ];

  BaseLook look(GameState s) => BaseLook(
        {for (final f in config.facilities) f.id: tierFor(s.facilityLevel(f.id))},
        activeDecorations(s).map((d) => d.id).toSet(),
        monuments(s).map((p) => p.id).toSet(),
      );

  /// Monuments standing on the base: one per planet ever reached, in order.
  /// Based on the most planets ever unlocked, so warps never remove them.
  /// The first planet's monument stands from the start.
  List<PlanetConfig> monuments(GameState s) {
    final reached = math.max(
      math.max(1, s.stat('maxPlanetsUnlocked').toInt()),
      s.unlockedPlanets.length,
    );
    return config.planets.take(reached).toList();
  }

  /// Facilities whose tier went up between two looks.
  List<Evolution> evolutions(BaseLook before, BaseLook after) => [
        for (final f in config.facilities)
          if ((after.tiers[f.id] ?? 0) > (before.tiers[f.id] ?? 0) && (after.tiers[f.id] ?? 0) > 1)
            Evolution(f, after.tiers[f.id]!, f.tierNames.isEmpty ? f.name : f.tierNames[after.tiers[f.id]! - 1]),
      ];

  /// Decorations that appeared between two looks.
  List<DecorationConfig> newDecorations(BaseLook before, BaseLook after) => [
        for (final d in config.visuals.decorations)
          if (after.decorations.contains(d.id) && !before.decorations.contains(d.id)) d,
      ];
}
