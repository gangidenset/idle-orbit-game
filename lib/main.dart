import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_env.dart';
import 'app/diagnostics.dart';
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

/// Name of the startup step in progress; included in error reports.
String _step = 'init';
bool _started = false;

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

  // If startup fails or hangs, show the error instead of an endless splash.
  final watchdog = Timer(const Duration(seconds: 15), () {
    if (!_started) _showStartupError('起動がタイムアウトしました（処理: $_step）', null);
  });
  try {
    await _start();
  } catch (e, st) {
    log.error('Startup failed at $_step', e, st);
    _showStartupError(e, st);
  } finally {
    watchdog.cancel();
  }
}

void _showStartupError(Object error, StackTrace? stack) {
  _started = true;
  runApp(StartupErrorApp(
    report: 'step: $_step\ndevice: ${deviceSummary()}\nenv: ${AppEnv.name}\n\n$error\n\n${stack ?? ''}',
  ));
}

Future<void> _start() async {
  _step = 'crash report';
  pendingCrashReport = await takeNativeCrashReport();

  _step = 'orientation';
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  _step = 'balance config';
  final config = BalanceConfig.fromJsonString(
      await rootBundle.loadString('assets/config/balance.json'));

  _step = 'storage';
  // Browser storage can be blocked (private mode, sandboxed frames). The game
  // still runs then; progress just isn't kept after closing.
  KeyValueStore store;
  var storageAvailable = true;
  try {
    store = SharedPrefsStore(await SharedPreferences.getInstance());
  } catch (e, st) {
    log.error('Storage unavailable; progress will not be saved', e, st);
    store = MemoryStore();
    storageAvailable = false;
  }

  // Optional services must never block the game from starting.
  _step = 'notifications';
  final NotificationService notifications =
      kIsWeb ? NoopNotificationService() : LocalNotificationService();
  await notifications.initialize().timeout(const Duration(seconds: 5), onTimeout: () {
    log.warn('Notification init timed out; continuing');
  });

  _step = 'game state';
  final controller = GameController(
    config: config,
    saveRepository: JsonSaveRepository(store),
    adService: _createAdService(),
    purchaseService: _createPurchaseService(config),
    analytics: LocalAnalyticsService(),
    notifications: notifications,
  );
  await controller.start();

  _step = 'ui';
  if (_started) return; // watchdog already showed an error screen
  _started = true;
  if (!storageAvailable) {
    controller.notifyStorageUnavailable();
  }
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
