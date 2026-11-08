/// Where a rewarded ad was requested from (for analytics / mediation).
enum RewardedPlacement { offlineDouble, productionBoost, freeReward }

enum RewardedOutcome {
  /// The user watched the ad and earned the reward.
  earned,

  /// The ad was shown but closed before the reward was earned.
  dismissed,

  /// No ad could be loaded/shown (no fill, offline, ads disabled...).
  unavailable,
}

class RewardedResult {
  const RewardedResult(this.outcome, [this.message]);
  final RewardedOutcome outcome;
  final String? message;
  bool get earned => outcome == RewardedOutcome.earned;
}

/// Abstraction over the ad network so the game runs without one.
abstract class AdService {
  Future<void> initialize();

  /// False when this build has no ad network at all (disabled/unconfigured).
  /// UI then disables ad buttons instead of letting them fail.
  bool get supported;

  /// Whether a rewarded ad is expected to be showable right now.
  bool get rewardedReady;

  /// Shows a rewarded ad. Only [RewardedOutcome.earned] may grant a reward.
  Future<RewardedResult> showRewarded(RewardedPlacement placement);

  /// Shows an interstitial if one is loaded. Returns true when shown.
  Future<bool> showInterstitial();

  void dispose();
}

/// Used when ads are disabled for the build or not configured.
/// It never pretends that an ad was watched.
class DisabledAdService implements AdService {
  const DisabledAdService([this.reason = '広告は現在利用できません。']);
  final String reason;

  @override
  Future<void> initialize() async {}

  @override
  bool get supported => false;

  @override
  bool get rewardedReady => false;

  @override
  Future<RewardedResult> showRewarded(RewardedPlacement placement) async =>
      RewardedResult(RewardedOutcome.unavailable, reason);

  @override
  Future<bool> showInterstitial() async => false;

  @override
  void dispose() {}
}
