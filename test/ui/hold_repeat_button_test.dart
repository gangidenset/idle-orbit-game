import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/features/facilities/facilities_screen.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/game/model/resources.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/audio/sound_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';
import 'package:idle_orbit/ui/hold_repeat_button.dart';
import 'package:idle_orbit/ui/widgets.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

void main() {
  late GameController c;

  Future<void> pump(WidgetTester tester, Widget child) async {
    c = GameController(
      config: loadBalance(),
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: const DisabledAdService(),
      purchaseService: UnavailablePurchaseService(),
      analytics: LocalAnalyticsService(),
      clock: FakeClock(t0),
    );
    await tester.runAsync(c.start);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: c),
        ChangeNotifierProvider(create: (_) => BuyMode()),
        Provider<SoundService>.value(value: const SilentSoundService()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ));
  }

  testWidgets('tap does one step; holding repeats, accelerates and stops on release',
      (tester) async {
    var steps = 0;
    final times = <Duration>[];
    var elapsed = Duration.zero;
    await pump(
      tester,
      Center(
        child: HoldRepeatButton(
          onStep: () {
            steps++;
            times.add(elapsed);
            return true;
          },
          child: const Text('強化'),
        ),
      ),
    );

    await tester.tap(find.text('強化'));
    await tester.pump();
    expect(steps, 1);

    steps = 0;
    times.clear();
    final g = await tester.startGesture(tester.getCenter(find.text('強化')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      elapsed += const Duration(milliseconds: 50);
    }
    expect(steps, greaterThan(10), reason: '2 s of holding repeats many times');
    final firstGap = times[1] - times[0];
    final lastGap = times.last - times[times.length - 2];
    expect(lastGap, lessThan(firstGap), reason: 'repeats speed up');
    expect(find.textContaining(RegExp(r'^\+\d+$')), findsWidgets, reason: 'shows the +N counter');

    await g.up();
    final after = steps;
    await tester.pump(const Duration(seconds: 1));
    expect(steps, after, reason: 'release stops repeating');
    c.dispose();
  });

  testWidgets('holding stops when a step fails', (tester) async {
    var budget = 3;
    await pump(
      tester,
      Center(
        child: HoldRepeatButton(
          onStep: () => budget-- > 0,
          child: const Text('強化'),
        ),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(find.text('強化')));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(budget, -1, reason: 'one failed attempt, then it stops trying');
    await g.up();
    c.dispose();
  });

  testWidgets('holding a facility upgrade raises its level many times', (tester) async {
    await pump(tester, const FacilitiesScreen());
    c.state.resources[ResourceType.ore] = 1e6;
    c.refresh();
    await tester.pump();
    final before = c.state.facilityLevel('ore_mine');
    final button = find.text('強化').first;
    final g = await tester.startGesture(tester.getCenter(button));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    expect(c.state.facilityLevel('ore_mine') - before, greaterThan(10));
    c.dispose();
  });
}
