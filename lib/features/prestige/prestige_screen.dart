import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/engine/game_engine.dart';
import '../../game/game_controller.dart';
import '../../game/model/game_state.dart';
import '../../ui/widgets.dart';

class PrestigeScreen extends StatelessWidget {
  const PrestigeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final ps = c.prestigeSystem;
    final cfg = c.config.prestige;
    final req = c.config.planet(cfg.requiredPlanet);
    final pts = ps.pointsAvailable(s);
    final can = ps.canPrestige(s);
    final reqMet = s.unlockedPlanets.contains(cfg.requiredPlanet);

    return Scaffold(
      appBar: AppBar(title: Text('転生（${cfg.name}）')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.rocket_launch, color: OrbitColors.accent),
                  SizedBox(width: 8),
                  Text('星系ワープとは？', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  '現在の星系を離れ、新しい星系で一から開拓をやり直します。\n'
                  'その代わり「ワープポイント」を獲得し、永久に残る強化に使えます。\n'
                  '強化は何度ワープしても失われないため、2回目以降はより速く進められます。',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                const _Bullets(title: 'リセットされるもの', color: OrbitColors.danger, items: [
                  '資源・施設レベル・ロボット・研究・惑星の開拓状況',
                ]),
                const SizedBox(height: 6),
                const _Bullets(title: '引き継がれるもの', color: OrbitColors.success, items: [
                  'ワープポイントと強化、実績、ミッション、司令官レベル',
                  'ショップで購入した商品・特典ロボット',
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: can ? OrbitColors.surfaceHigh : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Text('所持ワープポイント：${fmt(s.prestigePoints)}',
                    style: const TextStyle(fontSize: 14, color: OrbitColors.textDim)),
                const SizedBox(height: 6),
                Text('今ワープすると +$pts pt',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OrbitColors.accent)),
                const SizedBox(height: 4),
                Text('この星系での合金生産量 ${fmt(s.runStat(Metric.runAlloy))} に応じて増加',
                    style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                const SizedBox(height: 10),
                if (!reqMet)
                  Text('解放条件：${req.name} の開拓', style: const TextStyle(color: OrbitColors.danger)),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.rocket_launch),
                    onPressed: can ? () => _confirm(context, c, pts) : null,
                    label: Text(can ? 'ワープする' : (reqMet ? 'ポイントが足りません' : 'まだワープできません')),
                  ),
                ),
              ]),
            ),
          ),
          const SectionTitle('永久強化'),
          for (final u in cfg.upgrades)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${u.name}  Lv.${s.prestigeLevel(u.id)}/${u.maxLevel}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(u.description,
                            style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                        if (ps.upgradeBlock(s, u.id) != UpgradeBlock.maxLevel)
                          Text('必要：${fmt(ps.upgradeCost(s, u.id))} pt',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: s.prestigePoints >= ps.upgradeCost(s, u.id)
                                      ? OrbitColors.accent
                                      : OrbitColors.danger)),
                      ]),
                    ),
                    FilledButton(
                      onPressed: ps.upgradeBlock(s, u.id) == UpgradeBlock.none
                          ? () {
                              tapFeedback(context);
                              c.buyPrestigeUpgrade(u.id);
                            }
                          : null,
                      child: Text(ps.upgradeBlock(s, u.id) == UpgradeBlock.maxLevel ? 'MAX' : '強化'),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, GameController c, int pts) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('星系ワープしますか？'),
        content: Text('ワープポイント +$pts を獲得し、現在の開拓状況はリセットされます。\nこの操作は取り消せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('やめる')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ワープ')),
        ],
      ),
    );
    if (ok != true) return;
    final got = c.doPrestige();
    if (got > 0 && context.mounted) {
      showMessage(context, 'ワープ完了！ +$got pt を獲得しました。永久強化に使いましょう。');
    }
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.title, required this.color, required this.items});
  final String title;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        for (final i in items) Text('・$i', style: const TextStyle(fontSize: 12)),
      ]);
}
