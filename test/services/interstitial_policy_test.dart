import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/services/ads/interstitial_policy.dart';

import '../helpers.dart';

void main() {
  final cfg = loadBalance().interstitial;
  const s = 1000000;

  test('not in the first minutes of a session', () {
    final p = InterstitialPolicy(cfg, sessionStartMs: s);
    expect(p.canShow(nowMs: s + 10000, frequency: 'standard', noAds: false), isFalse);
    expect(
        p.canShow(
            nowMs: s + cfg.firstAfterSessionSeconds * 1000, frequency: 'standard', noAds: false),
        isTrue);
  });

  test('respects interval, frequency setting and session cap', () {
    final p = InterstitialPolicy(cfg, sessionStartMs: s);
    var now = s + cfg.firstAfterSessionSeconds * 1000;
    p.recordInterstitial(now);
    expect(p.canShow(nowMs: now + 1000, frequency: 'standard', noAds: false), isFalse);
    now += cfg.frequencies['standard']! * 1000;
    expect(p.canShow(nowMs: now, frequency: 'standard', noAds: false), isTrue);
    expect(p.canShow(nowMs: now, frequency: 'low', noAds: false), isFalse);
    for (var i = 0; i < cfg.maxPerSession; i++) {
      p.recordInterstitial(now);
      now += 100000000;
    }
    expect(p.canShow(nowMs: now, frequency: 'standard', noAds: false), isFalse);
  });

  test('never right after a rewarded ad or for no-ads owners', () {
    final p = InterstitialPolicy(cfg, sessionStartMs: s);
    final now = s + 3600 * 1000;
    expect(p.canShow(nowMs: now, frequency: 'standard', noAds: true), isFalse);
    p.recordRewarded(now);
    expect(p.canShow(nowMs: now + 1000, frequency: 'standard', noAds: false), isFalse);
  });
}
