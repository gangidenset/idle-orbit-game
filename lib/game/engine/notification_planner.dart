import 'dart:math' as math;

import '../model/game_state.dart';
import '../model/resources.dart';
import 'game_engine.dart';

enum ReminderKind { storageFull, offlineCapReached, researchDone }

class PlannedReminder {
  const PlannedReminder(this.kind, this.delay, this.title, this.body);
  final ReminderKind kind;
  final Duration delay;
  final String title;
  final String body;
}

/// Decides which local reminders to schedule when the player leaves.
///
/// At most two reminders, both tied to something actionable:
/// * a storage silo fills up (production is being wasted), and
/// * the offline reward cap is reached (time away no longer pays).
/// Nothing is scheduled for events less than [minDelay] away, so leaving
/// briefly never triggers a ping.
class NotificationPlanner {
  NotificationPlanner(this.engine, {this.minDelay = const Duration(minutes: 30)});

  final GameEngine engine;
  final Duration minDelay;

  List<PlannedReminder> plan(GameState s, int nowMs) {
    final mods = engine.modifiers(s);
    final snap = engine.snapshot(s, nowMs: nowMs, mods: mods, boostOverride: 1);
    final eff = math.max(0.01, mods.offlineEfficiency);
    final capSeconds = mods.offlineCapHours * 3600;
    final out = <PlannedReminder>[];

    ResourceType? first;
    var firstSeconds = double.infinity;
    for (final r in [ResourceType.ore, ResourceType.energy, ResourceType.alloy]) {
      final rate = snap.net[r] * eff;
      final cap = engine.storageCap(s, r, mods);
      if (rate <= 0 || !cap.isFinite || s.resources[r] >= cap) continue;
      final secs = (cap - s.resources[r]) / rate;
      if (secs < firstSeconds) {
        firstSeconds = secs;
        first = r;
      }
    }
    final storage = first;
    if (storage != null &&
        firstSeconds >= minDelay.inSeconds &&
        firstSeconds < capSeconds) {
      out.add(PlannedReminder(
        ReminderKind.storageFull,
        Duration(seconds: firstSeconds.round()),
        '${storage.label}の保管庫が満杯です',
        '生産が止まっています。保管施設を強化して、さらに資源を貯めましょう。',
      ));
    }

    // Research finishes on credited offline time, so only within the cap.
    final researching = s.activeResearch;
    final left = engine.researchRemaining(s);
    if (researching != null && left >= minDelay.inSeconds && left <= capSeconds) {
      out.add(PlannedReminder(
        ReminderKind.researchDone,
        Duration(seconds: left.round()),
        '研究が完了しました',
        '「${engine.config.researchNode(researching).name}」の研究が終わりました。次の研究を始めましょう。',
      ));
    }

    if (capSeconds >= minDelay.inSeconds) {
      out.add(PlannedReminder(
        ReminderKind.offlineCapReached,
        Duration(seconds: capSeconds.round()),
        '放置報酬が上限に達しました',
        '${capSeconds ~/ 3600}時間ぶんの資源が基地で待っています。受け取りに戻りましょう！',
      ));
    }
    return out;
  }
}
