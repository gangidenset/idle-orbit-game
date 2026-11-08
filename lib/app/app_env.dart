import 'package:flutter/foundation.dart';

/// Build-time environment, provided with `--dart-define` or
/// `--dart-define-from-file=.env` (see `.env.example`).
///
/// * `dev` (default): AdMob uses Google's public **test** ad units, purchases
///   go to the store sandbox / license-tester accounts.
/// * `prod`: real ad units must be supplied; if any is missing, ads are
///   disabled instead of silently falling back to test units.
class AppEnv {
  const AppEnv._();

  static const String name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static bool get isProd => name == 'prod';

  static const bool adsEnabled = bool.fromEnvironment('ADS_ENABLED', defaultValue: true);
  static const bool iapEnabled = bool.fromEnvironment('IAP_ENABLED', defaultValue: true);
  static const bool analyticsEnabled =
      bool.fromEnvironment('ANALYTICS_ENABLED', defaultValue: false);

  // Production ad unit ids (never commit real values; pass at build time).
  static const _rewardedAndroid = String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const _rewardedIos = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static const _interstitialAndroid = String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID');
  static const _interstitialIos = String.fromEnvironment('ADMOB_INTERSTITIAL_IOS');

  // Google's documented public test ad units.
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  static bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  /// Null means "no valid unit for this build" -> ads unavailable.
  static String? get rewardedUnitId {
    if (!isProd) return _isIos ? _testRewardedIos : _testRewardedAndroid;
    final id = _isIos ? _rewardedIos : _rewardedAndroid;
    return id.isEmpty ? null : id;
  }

  static String? get interstitialUnitId {
    if (!isProd) return _isIos ? _testInterstitialIos : _testInterstitialAndroid;
    final id = _isIos ? _interstitialIos : _interstitialAndroid;
    return id.isEmpty ? null : id;
  }

  static String get storePlatform => _isIos ? 'ios' : 'android';
}
