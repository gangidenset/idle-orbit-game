import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_env.dart';
import 'core/logger.dart';
import 'data/save_repository.dart';
import 'game/config/balance_config.dart';
import 'game/game_controller.dart';
import 'services/ads/ad_service.dart';
import 'services/ads/admob_ad_service.dart';
import 'services/analytics/analytics_service.dart';
import 'services/iap/purchase_service.dart';
import 'services/iap/store_purchase_service.dart';
import 'services/audio/sound_service.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log.error('FlutterError', details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log.error('Uncaught error', error, stack);
    return true;
  };
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final config = BalanceConfig.fromJsonString(
      await rootBundle.loadString('assets/config/balance.json'));
  final prefs = await SharedPreferences.getInstance();

  final notifications = kIsWeb ? NoopNotificationService() : LocalNotificationService();
  await notifications.initialize();

  final controller = GameController(
    config: config,
    saveRepository: JsonSaveRepository(SharedPrefsStore(prefs)),
    adService: _createAdService(),
    purchaseService: _createPurchaseService(config),
    analytics: LocalAnalyticsService(),
    notifications: notifications,
  );

  await controller.start();
  final sound = FlameSoundService(enabled: () => controller.state.settings.sound);
  runApp(IdleOrbitApp(controller: controller, sound: sound));
  unawaited(sound.initialize());

  // Ads and store load in the background; the game never waits for them.
  unawaited(controller.adService.initialize());
  unawaited(controller.purchaseService.initialize().then((_) => controller.refresh()));
}

AdService _createAdService() {
  if (!AppEnv.adsEnabled || kIsWeb) return const DisabledAdService();
  final rewarded = AppEnv.rewardedUnitId;
  if (rewarded == null) {
    log.warn('No rewarded ad unit configured for ${AppEnv.name}; ads disabled');
    return const DisabledAdService();
  }
  return AdMobAdService(
    rewardedUnitId: rewarded,
    interstitialUnitId: AppEnv.interstitialUnitId,
  );
}

PurchaseService _createPurchaseService(BalanceConfig config) {
  if (!AppEnv.iapEnabled || kIsWeb) return UnavailablePurchaseService();
  return StorePurchaseService(config.shop, AppEnv.storePlatform);
}
