import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/config/balance_config.dart';
import '../../game/game_controller.dart';
import '../../ui/widgets.dart';

String rewardText(RewardSpec r) => [
      if (r.productionMinutes > 0) '生産${fmt(r.productionMinutes)}分ぶん',
      for (final e in r.resources.nonZero) '${e.key.label} ${fmt(e.value)}',
      if (r.boostMinutes > 0) '生産ブースト${fmt(r.boostMinutes)}分',
    ].join(' + ');

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final p = c.progression;
    final login = p.nextLoginReward(s);
    final canLogin = p.canClaimLogin(s);
    final missions = p.missions(s);
    final achievements = p.achievements(s);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('ログインボーナス'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final lr in c.config.loginRewards)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _dayIndex(s.daily.loginDayIndex, c) > lr.day - 1
                            ? OrbitColors.surfaceHigh
                            : (lr == login && canLogin ? OrbitColors.primary.withValues(alpha: 0.25) : null),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: OrbitColors.outline),
                      ),
                      child: Column(children: [
                        Text('${lr.day}日', style: const TextStyle(fontSize: 11)),
                        Icon(lr.day == 7 ? Icons.star : Icons.card_giftcard,
                            size: 18,
                            color: _dayIndex(s.daily.loginDayIndex, c) > lr.day - 1
                                ? OrbitColors.success
                                : OrbitColors.accent),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              Text('${login.day}日目：${rewardText(login.reward)}', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canLogin
                      ? () {
                          final bag = c.claimLogin();
                          if (bag != null) showRewardDialog(context, 'ログインボーナス', bag);
                        }
                      : null,
                  child: Text(canLogin ? '受け取る' : '本日は受け取り済み・また明日！'),
                ),
              ),
            ]),
          ),
        ),
        const SectionTitle('デイリーミッション', trailing: Text('毎日0時に更新', style: TextStyle(fontSize: 11, color: OrbitColors.textDim))),
        for (final m in missions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.config.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                          value: m.ratio, minHeight: 5, borderRadius: BorderRadius.circular(3),
                          backgroundColor: OrbitColors.outline),
                      const SizedBox(height: 4),
                      Text(
                          '${fmt(m.progress.clamp(0, m.config.target).toDouble())} / ${fmt(m.config.target)}　報酬：${rewardText(m.config.reward)}',
                          style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: m.complete && !m.claimed
                        ? () {
                            final bag = c.claimMission(m.config.id);
                            if (bag != null) showRewardDialog(context, 'ミッション達成！', bag);
                          }
                        : null,
                    child: Text(m.claimed ? '達成済' : '受取'),
                  ),
                ]),
              ),
            ),
          ),
        SectionTitle('実績',
            trailing: Text(
                '全生産 +${fmtPercent(c.engine.achievementBonus(s))}',
                style: const TextStyle(fontSize: 12, color: OrbitColors.accent))),
        for (final a in achievements)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: ListTile(
                leading: Icon(a.claimed ? Icons.emoji_events : Icons.emoji_events_outlined,
                    color: a.claimed ? OrbitColors.accent : OrbitColors.textDim),
                title: Text(a.config.name),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${a.config.description}（報酬：全生産 +${fmtPercent(a.config.productionBonus)}）',
                      style: const TextStyle(fontSize: 11)),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: a.ratio, minHeight: 3, backgroundColor: OrbitColors.outline),
                ]),
                trailing: a.claimed
                    ? const Icon(Icons.check, color: OrbitColors.success)
                    : FilledButton(
                        onPressed: a.complete ? () => c.claimAchievement(a.config.id) : null,
                        child: const Text('受取'),
                      ),
              ),
            ),
          ),
      ],
    );
  }

  int _dayIndex(int idx, GameController c) => idx % c.config.loginRewards.length;
}
