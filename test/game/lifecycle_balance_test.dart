import 'package:flutter_test/flutter_test.dart';

import '../../tool/lifecycle_sim.dart';
import '../helpers.dart';

/// Guards long-term pacing including offline rewards and warps, for a player
/// with 4 short sessions a day (see tool/lifecycle_sim.dart).
void main() {
  test('multi-week pacing with prestige stays within target windows', () {
    final r = simulateLifecycle(loadBalance(), days: 16);
    final first = r.firstUnlock;

    expect(first['dunebell'], lessThan(1.5), reason: 'warp unlocks on day 1');
    expect(first['vulcara'], inInclusiveRange(2.5, 6.0), reason: 'planet 4 within week 1');
    expect(first['unknown'], inInclusiveRange(8.0, 16.0), reason: 'planet 5 in week 2');

    final warps = r.warps;
    expect(warps.first.points, greaterThanOrEqualTo(10), reason: 'first warp feels rewarding');

    // The second run must reach the warp gate clearly faster than the first.
    final run1 = r.reachedInRun('dunebell', 1)! - r.runStartDay(1);
    final run2 = r.reachedInRun('dunebell', 2)! - r.runStartDay(2);
    expect(run2, lessThan(run1 * 0.8));

    // Before the endgame, a run should take about a day, not stall.
    for (final w in warps.where((w) => w.day < 12).skip(1)) {
      final prev = warps[warps.indexOf(w) - 1].day;
      expect(w.day - prev, lessThanOrEqualTo(1.6), reason: 'run ending day ${w.day}');
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
