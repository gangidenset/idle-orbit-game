import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../../services/audio/sound_service.dart';
import '../../ui/widgets.dart';

/// Offline reward breakdown with an optional ad to double it.
Future<void> showOfflineRewardDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OfflineRewardDialog(),
  );
}

class _OfflineRewardDialog extends StatefulWidget {
  const _OfflineRewardDialog();

  @override
  State<_OfflineRewardDialog> createState() => _OfflineRewardDialogState();
}

class _OfflineRewardDialogState extends State<_OfflineRewardDialog> {
  bool _busy = false;

  Future<void> _claim(bool withAd) async {
    setState(() => _busy = true);
    final c = context.read<GameController>();
    final bag = await c.claimOfflineReward(withAd: withAd);
    if (!mounted) return;
    setState(() => _busy = false);
    // On ad failure the reward stays pending and the dialog stays open.
    if (bag != null) {
      if (!bag.isEmpty) playSfx(context, Sfx.reward);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final r = c.state.pendingOfflineReward;
    if (r == null) {
      return AlertDialog(
        content: const Text('報酬は受け取り済みです。'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる'))],
      );
    }
    final hasReward = r.creditedSeconds > 0 && !r.gained.isEmpty;
    final mult = c.config.offline.adMultiplier;
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.nightlight_round, color: OrbitColors.accent),
        SizedBox(width: 8),
        Text('おかえりなさい、司令官'),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (r.clockAnomaly)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('端末の時刻が過去に変更されたため、その期間の放置報酬は付与されません。',
                  style: TextStyle(color: OrbitColors.danger, fontSize: 12)),
            ),
          if (r.creditedSeconds > 0) ...[
            Text('留守の間 ${fmtDuration(Duration(seconds: r.elapsedSeconds))}、基地は稼働を続けました。'),
            if (r.capped)
              Text(
                '放置報酬は最大 ${fmtDuration(Duration(seconds: r.creditedSeconds))} まで（研究・転生で延長可能）',
                style: const TextStyle(fontSize: 11, color: OrbitColors.textDim),
              ),
            Text('放置効率 ${fmtPercent(c.mods.offlineEfficiency)}',
                style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
            const SizedBox(height: 12),
          ],
          RewardList(r.gained),
        ]),
      ),
      actions: [
        if (hasReward && c.rewardedAvailable)
          FilledButton.icon(
            onPressed: _busy ? null : () => _claim(true),
            icon: const Icon(Icons.play_circle),
            label: Text(adLabel(c, '×${fmt(mult)}で受け取る')),
          ),
        TextButton(
          onPressed: _busy ? null : () => _claim(false),
          child: Text(hasReward ? '受け取る' : '閉じる'),
        ),
      ],
      actionsOverflowDirection: VerticalDirection.up,
      actionsOverflowAlignment: OverflowBarAlignment.center,
    );
  }
}
