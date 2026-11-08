import '../../core/logger.dart';

/// Event names. Designed so the KPIs in docs/DESIGN.md (DAU, D1/D7,
/// session length, ARPDAU, LTV, ad view rate, ...) can be derived later.
abstract final class AnalyticsEvents {
  static const sessionStart = 'session_start_custom';
  static const sessionEnd = 'session_end_custom';
  static const facilityUpgrade = 'facility_upgrade';
  static const robotUpgrade = 'robot_upgrade';
  static const research = 'research_complete';
  static const planetUnlock = 'planet_unlock';
  static const prestige = 'prestige';
  static const offlineClaim = 'offline_claim';
  static const adRewardedRequest = 'ad_rewarded_request';
  static const adRewardedEarned = 'ad_rewarded_earned';
  static const adRewardedFailed = 'ad_rewarded_failed';
  static const adInterstitialShown = 'ad_interstitial_shown';
  static const purchaseStart = 'purchase_start';
  static const purchaseSuccess = 'purchase_success';
  static const purchaseFailed = 'purchase_failed';
  static const missionClaim = 'mission_claim';
  static const loginClaim = 'login_claim';
}

/// Analytics abstraction. No personal data is sent: only gameplay events
/// with anonymous parameters. A Firebase implementation can be added later
/// without touching game code.
abstract class AnalyticsService {
  void logEvent(String name, [Map<String, Object> params = const {}]);
  void setEnabled(bool enabled);
}

/// Default: logs locally only (no network).
class LocalAnalyticsService implements AnalyticsService {
  bool _enabled = true;

  @override
  void logEvent(String name, [Map<String, Object> params = const {}]) {
    if (!_enabled) return;
    log.info('[analytics] $name $params');
  }

  @override
  void setEnabled(bool enabled) => _enabled = enabled;
}
