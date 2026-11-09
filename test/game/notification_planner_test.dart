import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/engine/notification_planner.dart';
import 'package:idle_orbit/game/model/resources.dart';

import '../helpers.dart';

void main() {
  final engine = GameEngine(loadBalance());
  final planner = NotificationPlanner(engine);

  test('always reminds at the offline cap', () {
    final s = engine.newGame(t0);
    final plan = planner.plan(s, t0);
    final cap = plan.firstWhere((p) => p.kind == ReminderKind.offlineCapReached);
    expect(cap.delay, const Duration(hours: 8));
  });

  test('storage reminder when silo fills before the cap', () {
    // Base ore cap 1500 at 1 ore/s * 60% efficiency -> fills in ~41 min.
    final s = engine.newGame(t0)..resources[ResourceType.ore] = 0;
    final plan = planner.plan(s, t0);
    final st = plan.firstWhere((p) => p.kind == ReminderKind.storageFull);
    expect(st.delay.inMinutes, inInclusiveRange(40, 42));
    expect(st.title, contains('鉱石'));
  });

  test('no storage reminder if it fills too soon or is already full', () {
    final soon = engine.newGame(t0)..resources[ResourceType.ore] = 1400;
    expect(planner.plan(soon, t0).any((p) => p.kind == ReminderKind.storageFull), isFalse);
    final full = engine.newGame(t0)..resources[ResourceType.ore] = 1e6;
    expect(planner.plan(full, t0).any((p) => p.kind == ReminderKind.storageFull), isFalse);
  });

  test('no storage reminder if it would fill after the offline cap', () {
    final s = engine.newGame(t0)
      ..facilities['storage'] = 20
      ..resources[ResourceType.ore] = 0;
    expect(planner.plan(s, t0).map((p) => p.kind), [ReminderKind.offlineCapReached]);
  });
}
