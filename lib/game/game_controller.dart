import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../core/logger.dart';
import '../data/save_repository.dart';
import '../services/ads/ad_service.dart';
import '../services/ads/interstitial_policy.dart';
import '../services/analytics/analytics_service.dart';
import '../services/iap/purchase_service.dart';
import '../services/notifications/notification_service.dart';
import 'config/balance_config.dart';
import 'engine/game_engine.dart';
import 'engine/notification_planner.dart';
import 'engine/offline_calculator.dart';
import 'engine/prestige_system.dart';
import 'engine/progression_system.dart';
import 'model/game_state.dart';
import 'model/resources.dart';

/// One-off notifications for the UI (snackbars, celebrations).
sealed class GameEvent {}

class MessageEvent extends GameEvent {
  MessageEvent(this.text, {this.isError = false});
  final String text;
  final bool isError;
}

class PlanetUnlockedEvent extends GameEvent {
  PlanetUnlockedEvent(this.planet);
  final PlanetConfig planet;
}

class OfflineRewardEvent extends GameEvent {
  OfflineRewardEvent(this.reward);
  final OfflineReward reward;
}

/// Ask the player (in-game, before the OS prompt) to enable reminders.
class NotificationPromptEvent extends GameEvent {}

class PurchaseGrantedEvent extends GameEvent {
  PurchaseGrantedEvent(this.product, {required this.restored});
  final ProductConfig product;
  final bool restored;
}

/// Owns the [GameState] at runtime: ticking, saving, lifecycle, and
/// orchestration of ads/purchases/analytics around pure engine calls.
class GameController extends ChangeNotifier {
  GameController({
    required this.config,
    required this.saveRepository,
    required this.adService,
    required this.purchaseService,
    required this.analytics,
    NotificationService? notifications,
    Clock? clock,
  })  : clock = clock ?? SystemClock(),
        notifications = notifications ?? NoopNotificationService(),
        engine = GameEngine(config) {
    offline = OfflineCalculator(engine);
    planner = NotificationPlanner(engine);
    prestigeSystem = PrestigeSystem(engine);
    progression = ProgressionSystem(engine);
  }

  final BalanceConfig config;
  final SaveRepository saveRepository;
  final AdService adService;
  final PurchaseService purchaseService;
  final AnalyticsService analytics;
  final NotificationService notifications;
  final Clock clock;
  final GameEngine engine;
  late final OfflineCalculator offline;
  late final PrestigeSystem prestigeSystem;
  late final ProgressionSystem progression;
  late final NotificationPlanner planner;
  late InterstitialPolicy _interstitialPolicy;

  late GameState state;
  bool _started = false;
  bool get started => _started;

  final _events = StreamController<GameEvent>.broadcast();
  Stream<GameEvent> get events => _events.stream;

  Timer? _ticker;
  final Stopwatch _tickWatch = Stopwatch();
  double _sinceSave = 0;
  int _sessionStartMs = 0;
  bool _adInProgress = false;
  bool get adInProgress => _adInProgress;
  StreamSubscription<PurchaseEvent>? _purchaseSub;
  final Set<String> _pendingPurchases = {};

  /// Cached per-tick values for the UI.
  late Modifiers mods;
  late ProductionSnapshot snap;

  int get nowMs => clock.nowMs();

  // ------------------------------------------------------------- lifecycle

  Future<void> start() async {
    final loaded = await saveRepository.load();
    if (loaded.error != null) {
      _emit(MessageEvent(
          loaded.recoveredFromBackup
              ? 'セーブデータの読み込みに失敗したため、バックアップから復元しました。'
              : 'セーブデータを読み込めませんでした。新しいゲームを開始します。',
          isError: true));
    }
    final now = nowMs;
    state = loaded.state ?? engine.newGame(now);
    if (state.firstSessionDateKey.isEmpty) {
      state.firstSessionDateKey = ProgressionSystem.dateKeyOf(clock.nowLocal());
    }
    analytics.setEnabled(state.settings.analyticsConsent);
    _refreshCache();
    _started = true;

    _purchaseSub = purchaseService.events.listen(_onPurchaseEvent);
    _beginSession(fromColdStart: loaded.state != null);
    notifyListeners();
  }

  void _beginSession({required bool fromColdStart}) {
    final now = nowMs;
    _sessionStartMs = now;
    _interstitialPolicy = InterstitialPolicy(config.interstitial, sessionStartMs: now);
    state.addStat(Metric.sessions, 1);
    analytics.logEvent(AnalyticsEvents.sessionStart, {
      'prestige_count': state.stat(Metric.prestigeCount).toInt(),
      'planets': state.unlockedPlanets.length,
    });
    if (fromColdStart || state.pendingOfflineReward != null) {
      final r = offline.computeAndStore(state, now);
      if (r != null) _emit(OfflineRewardEvent(r));
    } else {
      state.lastSeenMs = now;
      state.highWaterMs = now > state.highWaterMs ? now : state.highWaterMs;
    }
    _rollDaily();
    _startTicker();
    unawaited(notifications.cancelAll()); // player is back
    _save();
  }

  void _endSession() {
    _stopTicker();
    if (state.settings.notifications) {
      unawaited(notifications.schedule(planner.plan(state, nowMs)));
    }
    final now = nowMs;
    analytics.logEvent(AnalyticsEvents.sessionEnd,
        {'duration_s': ((now - _sessionStartMs) / 1000).round()});
    _touchClock();
    _save();
  }

  /// Called from the app lifecycle observer.
  void onPaused() {
    if (!_started) return;
    _endSession();
  }

  void onResumed() {
    if (!_started) return;
    _beginSession(fromColdStart: true);
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _tickWatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      Duration(milliseconds: (config.tickSeconds * 1000).round()),
      (_) => _onTick(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _tickWatch.stop();
  }

  void _onTick() {
    // Monotonic time: changing the device clock during play has no effect.
    var dt = _tickWatch.elapsedMicroseconds / 1e6;
    _tickWatch
      ..reset()
      ..start();
    if (dt > 5) dt = 5; // e.g. process was frozen without a pause event
    advance(dt);
  }

  /// Advances the game by [dt] seconds of active play. Public for tests.
  void advance(double dt) {
    engine.tick(state, dt, nowMs: nowMs, mods: mods);
    _sinceSave += dt;
    if (_sinceSave >= config.autosaveSeconds) {
      _sinceSave = 0;
      _touchClock();
      _rollDaily();
      _save();
    }
    _refreshCache();
    notifyListeners();
  }

  void _touchClock() {
    final now = nowMs;
    state.lastSeenMs = now;
    if (now > state.highWaterMs) state.highWaterMs = now;
  }

  void _rollDaily() {
    final now = nowMs;
    if (now < state.highWaterMs - OfflineCalculator.rollbackToleranceMs) return;
    progression.ensureDaily(state, ProgressionSystem.dateKeyOf(clock.nowLocal()));
  }

  void _refreshCache() {
    mods = engine.modifiers(state);
    snap = engine.snapshot(state, nowMs: nowMs, mods: mods);
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    try {
      await saveRepository.save(state);
    } catch (e, st) {
      log.error('Save failed', e, st);
      _emit(MessageEvent('進行状況の保存に失敗しました。端末の空き容量をご確認ください。', isError: true));
    }
  }

  Future<void> saveNow() async {
    _touchClock();
    await _save();
  }

  /// Tells the player that progress can't be saved in this environment.
  void notifyStorageUnavailable() {
    Timer(const Duration(seconds: 1), () => _emit(MessageEvent(
        'このブラウザではデータを保存できません。閉じると進行状況は失われます。',
        isError: true)));
  }

  /// Rebuilds listeners after an external service changed (e.g. store ready).
  void refresh() => notifyListeners();

  void _emit(GameEvent e) {
    if (!_events.isClosed) _events.add(e);
  }

  /// Applies a state change, refreshes caches, notifies and saves.
  /// Saves are debounced so bursts (e.g. holding an upgrade button) write
  /// once; leaving the app still saves immediately.
  void _commit({bool save = true}) {
    _refreshCache();
    notifyListeners();
    if (save) _saveSoon();
  }

  Timer? _saveTimer;

  void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 800), () {
      _saveTimer = null;
      _save();
    });
  }

  // ------------------------------------------------------------- gameplay

  int upgradeFacility(String id, {int count = 1}) {
    final n = engine.upgradeFacilityMany(state, id, count);
    if (n > 0) {
      analytics.logEvent(AnalyticsEvents.facilityUpgrade,
          {'facility': id, 'level': state.facilityLevel(id), 'count': n});
      _commit();
    }
    return n;
  }

  bool upgradeRobot(String id) {
    if (!engine.upgradeRobot(state, id)) return false;
    analytics.logEvent(
        AnalyticsEvents.robotUpgrade, {'robot': id, 'level': state.robotLevel(id)});
    _commit();
    return true;
  }

  bool doResearch(String id) {
    if (!engine.doResearch(state, id)) return false;
    analytics.logEvent(
        AnalyticsEvents.research, {'research': id, 'level': state.researchLevel(id)});
    _commit();
    return true;
  }

  bool unlockPlanet(String id) {
    if (!engine.unlockPlanet(state, id)) return false;
    final p = config.planet(id);
    analytics.logEvent(AnalyticsEvents.planetUnlock,
        {'planet': id, 'index': config.planetIndex(id), 'prestige': state.stat(Metric.prestigeCount).toInt()});
    _emit(PlanetUnlockedEvent(p));
    _commit();
    return true;
  }

  void setActivePlanet(String id) {
    if (engine.setActivePlanet(state, id)) _commit();
  }

  // --------------------------------------------------------------- ads

  /// Runs the rewarded-ad flow. Returns true only if the reward is earned.
  Future<bool> _watchRewarded(RewardedPlacement placement) async {
    if (engine.skipsRewardedAds(state)) return true;
    if (_adInProgress) return false;
    _adInProgress = true;
    notifyListeners();
    analytics.logEvent(AnalyticsEvents.adRewardedRequest, {'placement': placement.name});
    try {
      _stopTicker();
      final r = await adService.showRewarded(placement);
      _interstitialPolicy.recordRewarded(nowMs);
      if (r.earned) {
        state.addStat(Metric.adsWatched, 1);
        analytics.logEvent(AnalyticsEvents.adRewardedEarned, {'placement': placement.name});
        return true;
      }
      analytics.logEvent(AnalyticsEvents.adRewardedFailed,
          {'placement': placement.name, 'outcome': r.outcome.name});
      _emit(MessageEvent(r.message ?? '広告を表示できませんでした。報酬は付与されていません。',
          isError: true));
      return false;
    } catch (e, st) {
      log.error('Rewarded ad flow failed', e, st);
      _emit(MessageEvent('広告の表示中にエラーが発生しました。報酬は付与されていません。', isError: true));
      return false;
    } finally {
      _adInProgress = false;
      _startTicker();
      notifyListeners();
    }
  }

  bool get rewardedSkips => engine.skipsRewardedAds(state);

  /// Whether rewarded actions can be offered at all in this build.
  bool get rewardedAvailable => rewardedSkips || adService.supported;

  Future<ResourceBag?> claimOfflineReward({required bool withAd}) async {
    final r = state.pendingOfflineReward;
    if (r == null) return null;
    var mult = 1.0;
    if (withAd && r.creditedSeconds > 0) {
      if (!await _watchRewarded(RewardedPlacement.offlineDouble)) return null;
      mult = config.offline.adMultiplier;
    }
    final bag = offline.claim(state, multiplier: mult);
    analytics.logEvent(AnalyticsEvents.offlineClaim,
        {'seconds': r.creditedSeconds, 'ad': withAd, 'capped': r.capped});
    if (r.creditedSeconds > 0 &&
        !state.settings.notificationPromptShown &&
        !state.settings.notifications) {
      state.settings.notificationPromptShown = true;
      _emit(NotificationPromptEvent());
    }
    _commit();
    return bag;
  }

  Future<bool> activateAdBoost() async {
    if (!engine.canExtendAdBoost(state, nowMs)) {
      _emit(MessageEvent('ブーストはこれ以上延長できません。'));
      return false;
    }
    if (!await _watchRewarded(RewardedPlacement.productionBoost)) return false;
    final b = config.adBoost;
    engine.addBoost(state,
        source: 'ad',
        multiplier: b.multiplier,
        minutes: b.minutes,
        maxStackMinutes: b.maxStackMinutes,
        nowMs: nowMs);
    _commit();
    return true;
  }

  Future<ResourceBag?> claimFreeReward() async {
    if (engine.freeRewardCooldown(state, nowMs) > Duration.zero) return null;
    if (!await _watchRewarded(RewardedPlacement.freeReward)) return null;
    final bag = engine.claimFreeReward(state, nowMs);
    _commit();
    return bag;
  }

  /// Call at natural breaks only (closing a sub-screen, after a celebration).
  Future<void> maybeShowInterstitial(String trigger) async {
    final now = nowMs;
    if (_adInProgress) return;
    if (!_interstitialPolicy.canShow(
        nowMs: now, frequency: state.settings.adFrequency, noAds: engine.noAds(state))) {
      return;
    }
    _adInProgress = true;
    try {
      _stopTicker();
      final shown = await adService.showInterstitial();
      if (shown) {
        _interstitialPolicy.recordInterstitial(nowMs);
        analytics.logEvent(AnalyticsEvents.adInterstitialShown, {'trigger': trigger});
      }
    } catch (e, st) {
      log.error('Interstitial failed', e, st);
    } finally {
      _adInProgress = false;
      _startTicker();
    }
  }

  // ------------------------------------------------------ daily / meta

  ResourceBag? claimLogin() {
    final r = progression.claimLogin(state, nowMs);
    if (r != null) {
      analytics.logEvent(AnalyticsEvents.loginClaim, {'day': state.daily.loginDayIndex});
      _commit();
    }
    return r;
  }

  ResourceBag? claimMission(String id) {
    final r = progression.claimMission(state, id, nowMs);
    if (r != null) {
      analytics.logEvent(AnalyticsEvents.missionClaim, {'mission': id});
      _commit();
    }
    return r;
  }

  bool claimAchievement(String id) {
    final ok = progression.claimAchievement(state, id);
    if (ok) _commit();
    return ok;
  }

  int doPrestige() {
    final pts = prestigeSystem.prestige(state, nowMs);
    if (pts > 0) {
      analytics.logEvent(AnalyticsEvents.prestige,
          {'points': pts, 'count': state.stat(Metric.prestigeCount).toInt()});
      _commit();
    }
    return pts;
  }

  bool buyPrestigeUpgrade(String id) {
    final ok = prestigeSystem.buyUpgrade(state, id);
    if (ok) _commit();
    return ok;
  }

  // ------------------------------------------------------------ purchases

  bool isPurchasePending(String productId) => _pendingPurchases.contains(productId);

  bool ownsProduct(ProductConfig p) =>
      p.kind == ProductKind.nonConsumable &&
      p.grantEntitlement != null &&
      state.has(p.grantEntitlement!);

  Future<void> buy(String productId) async {
    analytics.logEvent(AnalyticsEvents.purchaseStart, {'product': productId});
    final r = await purchaseService.buy(productId);
    switch (r) {
      case BuyStartResult.started:
        _pendingPurchases.add(productId);
        notifyListeners();
      case BuyStartResult.unavailable:
        _emit(MessageEvent('ストアに接続できません。時間をおいて再度お試しください。', isError: true));
      case BuyStartResult.unknownProduct:
        _emit(MessageEvent('この商品は現在購入できません。', isError: true));
      case BuyStartResult.error:
        _emit(MessageEvent('購入を開始できませんでした。', isError: true));
    }
  }

  Future<void> restorePurchases() async {
    final ok = await purchaseService.restore();
    _emit(ok
        ? MessageEvent('購入の復元を要求しました。対象の商品があれば自動で反映されます。')
        : MessageEvent('ストアに接続できないため復元できませんでした。', isError: true));
  }

  Future<void> _onPurchaseEvent(PurchaseEvent e) async {
    final product = config.shop.byId(e.productId);
    switch (e.status) {
      case PurchaseEventStatus.pending:
        _pendingPurchases.add(e.productId);
        _emit(MessageEvent('購入処理を待っています…'));
      case PurchaseEventStatus.purchased:
      case PurchaseEventStatus.restored:
        _pendingPurchases.remove(e.productId);
        if (product == null) break;
        final granted = engine.applyPurchase(state, product, e.transactionId, nowMs);
        // Persist BEFORE acknowledging, so a crash cannot lose the item.
        await _save();
        try {
          await e.complete?.call();
        } catch (err, st) {
          log.error('completePurchase failed', err, st);
        }
        if (granted) {
          analytics.logEvent(AnalyticsEvents.purchaseSuccess, {
            'product': product.id,
            'restored': e.status == PurchaseEventStatus.restored,
          });
          _emit(PurchaseGrantedEvent(product,
              restored: e.status == PurchaseEventStatus.restored));
        }
        _commit(save: false);
      case PurchaseEventStatus.cancelled:
        _pendingPurchases.remove(e.productId);
        await e.complete?.call();
        _emit(MessageEvent('購入をキャンセルしました。'));
        notifyListeners();
      case PurchaseEventStatus.error:
        _pendingPurchases.remove(e.productId);
        await e.complete?.call();
        analytics.logEvent(AnalyticsEvents.purchaseFailed, {'product': e.productId});
        _emit(MessageEvent('購入に失敗しました。料金は請求されていません。${e.message ?? ''}',
            isError: true));
        notifyListeners();
    }
  }

  // ------------------------------------------------------------- settings

  void setAdFrequency(String f) {
    state.settings.adFrequency = f;
    _commit();
  }

  void setHaptics(bool v) {
    state.settings.haptics = v;
    _commit();
  }

  void setSound(bool v) {
    state.settings.sound = v;
    _commit();
  }

  /// Turning reminders on requests OS permission; stays off if denied.
  Future<bool> setNotifications(bool v) async {
    if (v) {
      final granted = await notifications.requestPermission();
      state.settings.notifications = granted;
      if (!granted) {
        _emit(MessageEvent('通知が許可されていません。端末の設定アプリから「IDLE ORBIT」の通知を許可してください。',
            isError: true));
      }
    } else {
      state.settings.notifications = false;
      unawaited(notifications.cancelAll());
    }
    _commit();
    return state.settings.notifications;
  }

  void setAnalyticsConsent(bool v) {
    state.settings.analyticsConsent = v;
    analytics.setEnabled(v);
    _commit();
  }

  /// Deletes all progress except purchases (which remain restorable).
  Future<void> resetAllData() async {
    final keep = state.entitlements;
    final keepTx = state.processedPurchaseIds;
    final settings = state.settings;
    state = engine.newGame(nowMs)
      ..entitlements = keep
      ..processedPurchaseIds = keepTx
      ..settings = settings;
    if (state.has('starter_pack')) state.robots['pioneer_bot'] = 1;
    _rollDaily();
    _commit();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _stopTicker();
    _purchaseSub?.cancel();
    _events.close();
    super.dispose();
  }
}
