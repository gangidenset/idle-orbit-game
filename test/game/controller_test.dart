import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/core/clock.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/game/game_controller.dart';
import 'package:idle_orbit/game/model/game_state.dart';
import 'package:idle_orbit/game/model/resources.dart';
import 'package:idle_orbit/services/ads/ad_service.dart';
import 'package:idle_orbit/services/analytics/analytics_service.dart';
import 'package:idle_orbit/services/iap/purchase_service.dart';

import '../helpers.dart';

/// Test double: outcome is scripted per test.
class ScriptedAds implements AdService {
  RewardedOutcome next = RewardedOutcome.earned;
  int shown = 0;
  @override
  Future<void> initialize() async {}
  @override
  bool get supported => true;
  @override
  bool get rewardedReady => true;
  @override
  Future<RewardedResult> showRewarded(RewardedPlacement p) async {
    shown++;
    return RewardedResult(next, next == RewardedOutcome.earned ? null : 'failed');
  }

  @override
  Future<bool> showInterstitial() async => true;
  @override
  void dispose() {}
}

class FakeStore implements PurchaseService {
  final controller = StreamController<PurchaseEvent>.broadcast();
  bool completed = false;
  @override
  Future<void> initialize() async {}
  @override
  bool get isAvailable => true;
  @override
  Map<String, StoreProduct> get products => const {};
  @override
  Stream<PurchaseEvent> get events => controller.stream;
  @override
  Future<BuyStartResult> buy(String productId) async => BuyStartResult.started;
  @override
  Future<bool> restore() async => true;
  @override
  void dispose() {}
}

void main() {
  late FakeClock clock;
  late MemoryStore store;
  late ScriptedAds ads;
  late FakeStore iap;

  GameController make() => GameController(
        config: loadBalance(),
        saveRepository: JsonSaveRepository(store),
        adService: ads,
        purchaseService: iap,
        analytics: LocalAnalyticsService(),
        clock: clock,
      );

  setUp(() {
    clock = FakeClock(t0);
    store = MemoryStore();
    ads = ScriptedAds();
    iap = FakeStore();
  });

  test('new game starts, ticks, and saves', () async {
    final c = make();
    await c.start();
    c.advance(10);
    expect(c.state.resources[ResourceType.ore], greaterThan(30));
    await c.saveNow();
    expect(store.data.containsKey(JsonSaveRepository.primaryKey), isTrue);
    c.dispose();
  });

  test('offline reward after restart; failed ad grants nothing', () async {
    final c1 = make();
    await c1.start();
    c1.onPaused();
    c1.dispose();
    await Future<void>.delayed(Duration.zero);

    clock.advance(const Duration(hours: 2));
    final c2 = make();
    await c2.start();
    expect(c2.state.pendingOfflineReward, isNotNull);
    final ore = c2.state.resources[ResourceType.ore];

    ads.next = RewardedOutcome.unavailable;
    expect(await c2.claimOfflineReward(withAd: true), isNull);
    expect(c2.state.resources[ResourceType.ore], ore, reason: 'no reward on ad failure');
    expect(c2.state.pendingOfflineReward, isNotNull, reason: 'reward kept for retry');

    ads.next = RewardedOutcome.earned;
    final got = await c2.claimOfflineReward(withAd: true);
    expect(got, isNotNull);
    expect(got![ResourceType.ore],
        closeTo(c2.config.offline.adMultiplier * (got[ResourceType.ore] / 2), 1e-6));
    expect(c2.state.pendingOfflineReward, isNull);
    c2.dispose();
  });

  test('dismissed rewarded ad does not grant boost', () async {
    final c = make();
    await c.start();
    ads.next = RewardedOutcome.dismissed;
    expect(await c.activateAdBoost(), isFalse);
    expect(c.engine.boostMultiplier(c.state, clock.nowMs()), 1);
    ads.next = RewardedOutcome.earned;
    expect(await c.activateAdBoost(), isTrue);
    expect(c.engine.boostMultiplier(c.state, clock.nowMs()), 2);
    c.dispose();
  });

  test('premium skips rewarded ads entirely', () async {
    final c = make();
    await c.start();
    c.state.entitlements.add('premium');
    expect(await c.activateAdBoost(), isTrue);
    expect(ads.shown, 0);
    c.dispose();
  });

  test('purchase granted only on store event, saved before completion', () async {
    final c = make();
    await c.start();
    await c.buy('remove_ads');
    expect(c.state.has('no_ads'), isFalse, reason: 'starting a purchase grants nothing');

    var savedBeforeComplete = false;
    iap.controller.add(PurchaseEvent(
      productId: 'remove_ads',
      status: PurchaseEventStatus.purchased,
      transactionId: 'GPA.1',
      complete: () async {
        savedBeforeComplete =
            store.data[JsonSaveRepository.primaryKey]!.contains('no_ads');
      },
    ));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.state.has('no_ads'), isTrue);
    expect(savedBeforeComplete, isTrue);

    iap.controller.add(PurchaseEvent(productId: 'starter_pack', status: PurchaseEventStatus.error));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.state.has('starter_pack'), isFalse);
    c.dispose();
  });

  test('reset keeps purchases', () async {
    final c = make();
    await c.start();
    c.state.entitlements.add('no_ads');
    c.state.facilities['ore_mine'] = 20;
    await c.resetAllData();
    expect(c.state.facilityLevel('ore_mine'), 1);
    expect(c.state.has('no_ads'), isTrue);
    c.dispose();
  });

  test('session counter and daily missions initialise', () async {
    final c = make();
    await c.start();
    expect(c.state.stat(Metric.sessions), 1);
    expect(c.state.daily.missionIds, isNotEmpty);
    c.dispose();
  });
}
