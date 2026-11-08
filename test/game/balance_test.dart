import 'package:flutter_test/flutter_test.dart';

import '../../tool/balance_sim.dart';
import '../helpers.dart';

/// Guards the early-game pacing so balance.json edits don't break the
/// first-session experience. Active play only (no offline rewards / ads).
void main() {
  test('early planet pacing stays within target windows', () {
    final at = simulate(loadBalance(), hours: 4);
    final p2 = at['glacies']! / 60;
    final p3 = at['dunebell']! / 60;
    expect(p2, inInclusiveRange(8, 30), reason: 'planet 2 in first session');
    expect(p3, inInclusiveRange(45, 240), reason: 'planet 3 (prestige gate) on day 1');
    expect(at.containsKey('unknown'), isFalse, reason: 'planet 5 must not be reachable quickly');
  });
}
