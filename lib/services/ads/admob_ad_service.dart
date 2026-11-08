import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/logger.dart';
import 'ad_service.dart';

/// Google AdMob implementation. Ad unit ids come from [AppEnv]
/// (Google test units in dev, real units in prod).
class AdMobAdService implements AdService {
  AdMobAdService({required this.rewardedUnitId, required this.interstitialUnitId});

  final String rewardedUnitId;
  final String? interstitialUnitId;

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;
  bool _initialized = false;
  Completer<void>? _rewardedLoad;

  static const _loadTimeout = Duration(seconds: 10);

  @override
  Future<void> initialize() async {
    try {
      await _gatherConsent();
      await MobileAds.instance.initialize();
      _initialized = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (e, st) {
      log.error('AdMob init failed; ads unavailable', e, st);
    }
  }

  /// Google UMP consent flow (GDPR/ATT). Required for regions where it
  /// applies; a no-op elsewhere.
  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) log.warn('Consent form: ${error.message}');
          if (!done.isCompleted) done.complete();
        });
      },
      (error) {
        log.warn('Consent info update failed: ${error.message}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
  }

  void _loadRewarded() {
    if (!_initialized || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    _rewardedLoad = Completer<void>();
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          _rewardedLoad?.complete();
        },
        onAdFailedToLoad: (error) {
          log.warn('Rewarded failed to load: ${error.code} ${error.message}');
          _loadingRewarded = false;
          _rewardedLoad?.complete();
        },
      ),
    );
  }

  void _loadInterstitial() {
    final id = interstitialUnitId;
    if (!_initialized || id == null || _loadingInterstitial || _interstitial != null) {
      return;
    }
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          log.warn('Interstitial failed to load: ${error.code} ${error.message}');
          _loadingInterstitial = false;
        },
      ),
    );
  }

  @override
  bool get supported => true;

  @override
  bool get rewardedReady => _rewarded != null;

  @override
  Future<RewardedResult> showRewarded(RewardedPlacement placement) async {
    if (!_initialized) {
      return const RewardedResult(
          RewardedOutcome.unavailable, '広告を読み込めませんでした。通信環境をご確認ください。');
    }
    if (_rewarded == null) {
      _loadRewarded();
      await _rewardedLoad?.future.timeout(_loadTimeout, onTimeout: () {});
    }
    final ad = _rewarded;
    if (ad == null) {
      return const RewardedResult(RewardedOutcome.unavailable,
          '現在表示できる広告がありません。時間をおいて再度お試しください。');
    }
    _rewarded = null;

    final result = Completer<RewardedResult>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) {
          result.complete(earned
              ? const RewardedResult(RewardedOutcome.earned)
              : const RewardedResult(
                  RewardedOutcome.dismissed, '最後まで視聴すると報酬を獲得できます。'));
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        log.warn('Rewarded failed to show: ${error.message}');
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) {
          result.complete(const RewardedResult(
              RewardedOutcome.unavailable, '広告を表示できませんでした。報酬は付与されていません。'));
        }
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return result.future;
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show();
    return done.future;
  }

  @override
  void dispose() {
    _rewarded?.dispose();
    _interstitial?.dispose();
  }
}
