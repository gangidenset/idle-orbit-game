import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/app/app.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';

import '../helpers.dart';

/// Pumps the real app with ads/store unavailable and visits every screen.
void main() {
  testWidgets('every tab and menu screen builds without errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final c = GameController(
      config: loadBalance(),
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: const DisabledAdService(),
      purchaseService: UnavailablePurchaseService(),
      analytics: LocalAnalyticsService(),
      clock: FakeClock(t0),
    );
    await tester.runAsync(c.start);
    // The Flame scene animates forever, so pumpAndSettle can't be used.
    Future<void> frames() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(IdleOrbitApp(controller: c));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('始まりの惑星 テラノヴァ'), findsOneWidget);
    expect(find.text('鉱石採掘施設'), findsWidgets);

    for (final tab in ['施設', 'ロボット', '研究', 'ミッション', '基地']) {
      await tester.tap(find.text(tab).last);
      await frames();
    }
    expect(find.text('研究はまだ利用できません', skipOffstage: false), findsOneWidget);

    for (final (menu, title) in [
      ('惑星', '惑星開拓'),
      ('転生（星系ワープ）', '転生（星系ワープ）'),
      ('ショップ', 'ショップ'),
      ('設定', '設定'),
    ]) {
      await tester.tap(find.byTooltip('メニュー'));
      await frames();
      await tester.tap(find.text(menu).last);
      await frames();
      expect(find.text(title), findsWidgets);
      await tester.pageBack();
      await frames();
    }
    expect(find.text('ストアに接続できません'), findsNothing); // shop closed again

    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
