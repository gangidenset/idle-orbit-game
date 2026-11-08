import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/features/planets/planets_screen.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/game/model/resources.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';
import 'package:provider/provider.dart';

import '../helpers.dart';

void main() {
  testWidgets('tapping 開拓 unlocks the next planet', (tester) async {
    final c = GameController(
      config: loadBalance(),
      saveRepository: JsonSaveRepository(MemoryStore()),
      adService: const DisabledAdService(),
      purchaseService: UnavailablePurchaseService(),
      analytics: LocalAnalyticsService(),
      clock: FakeClock(t0),
    );
    await tester.runAsync(c.start);
    c.state.resources[ResourceType.alloy] = 1e6;
    c.state.resources[ResourceType.research] = 1e6;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: c,
      child: const MaterialApp(home: PlanetsScreen()),
    ));
    await tester.tap(find.text('開拓'));
    await tester.pump();
    expect(c.state.unlockedPlanets, contains('glacies'));
    c.dispose();
  });
}
