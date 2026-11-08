import '../../game/config/balance_config.dart';

/// Decides whether an interstitial may be shown at a natural break.
///
/// Rules (all configurable in balance.json):
/// * never for players who bought ad removal
/// * never in the first N seconds of a session
/// * at least `frequency` seconds between interstitials
/// * never shortly after a rewarded ad
/// * at most M per session
class InterstitialPolicy {
  InterstitialPolicy(this.config, {required this.sessionStartMs});

  final InterstitialConfig config;
  final int sessionStartMs;
  int? _lastInterstitialMs;
  int? _lastRewardedMs;
  int _shownThisSession = 0;

  int get shownThisSession => _shownThisSession;

  int intervalSeconds(String frequency) =>
      config.frequencies[frequency] ??
      config.frequencies[config.defaultFrequency] ??
      300;

  bool canShow({required int nowMs, required String frequency, required bool noAds}) {
    if (noAds) return false;
    if (_shownThisSession >= config.maxPerSession) return false;
    if (nowMs - sessionStartMs < config.firstAfterSessionSeconds * 1000) return false;
    final last = _lastInterstitialMs;
    if (last != null && nowMs - last < intervalSeconds(frequency) * 1000) return false;
    final rew = _lastRewardedMs;
    if (rew != null && nowMs - rew < config.cooldownAfterRewardedSeconds * 1000) {
      return false;
    }
    return true;
  }

  void recordInterstitial(int nowMs) {
    _lastInterstitialMs = nowMs;
    _shownThisSession++;
  }

  void recordRewarded(int nowMs) => _lastRewardedMs = nowMs;
}
