import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/app/app.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/features/base/base_view_screen.dart';
import 'package:idle_orbit/flame/orbit_scene.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';

import '../helpers.dart';

void main() {
  testWidgets('tapping the planet opens the zoomable base view with growth summary',
      (tester) async {
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
    c.state.facilities['ore_mine'] = 30; // tier 3
    c.state.research['drill_tech'] = 3; // city lights
    c.refresh();

    Future<void> frames() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.pumpWidget(IdleOrbitApp(controller: c));
    await frames();

    await tester.tap(find.byWidgetPredicate((w) => w is GameWidget).first);
    await frames();
    expect(find.byType(BaseViewScreen), findsOneWidget);
    expect(find.text('基地の成長'), findsOneWidget);
    expect(find.text('深層掘削基地'), findsOneWidget, reason: 'ore mine tier 3 name');
    expect(find.text('Lv.30・あと20で進化'), findsOneWidget);
    // 1 decoration of 7 unlocked; the rest show as locked with a condition.
    expect(find.text('1 / 7'), findsOneWidget);
    expect(find.text('1 / 5'), findsOneWidget, reason: 'first monument stands from the start');
    // One-finger horizontal drag turns the planet.
    final scene = tester
        .widgetList<GameWidget>(find.byWidgetPredicate((w) => w is GameWidget))
        .map((w) => w.game)
        .whereType<OrbitScene>()
        .last;
    expect(scene.yaw, 0);
    await tester.dragFrom(const Offset(200, 300), const Offset(-150, 0));
    await frames();
    expect(scene.yaw, isNot(closeTo(0, 0.05)), reason: 'dragging spins the planet');

    double zoom() => tester
        .widget<Transform>(find.byKey(const ValueKey('base-view-transform')))
        .transform
        .getMaxScaleOnAxis();

    await tester.tap(find.text('基地をアップ'));
    await frames();
    // Flame's own loop doesn't run under the test clock; step it manually.
    for (var i = 0; i < 120; i++) {
      scene.update(1 / 60);
    }
    expect(zoom(), greaterThanOrEqualTo(1.5), reason: 'close-up zooms in');
    expect(scene.yaw.abs() % (2 * 3.14159265), anyOf(lessThan(0.01), greaterThan(6.27)),
        reason: 'close-up turns the planet back to the front');
    await tester.tap(find.text('全体'));
    await frames();
    expect(zoom(), closeTo(1, 0.01));

    // Pull the summary sheet up to see the collection.
    await tester.drag(find.text('基地の成長'), const Offset(0, -900));
    await frames();
    expect(find.text('テラノヴァ着陸記念碑'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('夜の街明かり'), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text('夜の街明かり'), findsOneWidget);
    expect(find.textContaining('解放条件：'), findsWidgets);


    await tester.tap(find.byTooltip('閉じる'));
    await frames();
    expect(find.byType(BaseViewScreen), findsNothing);
    c.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
