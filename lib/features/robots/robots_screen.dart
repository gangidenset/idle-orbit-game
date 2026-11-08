import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/config/balance_config.dart';
import '../../game/engine/game_engine.dart';
import '../../game/game_controller.dart';
import '../../ui/widgets.dart';
import '../facilities/facility_tile.dart';

class RobotsScreen extends StatelessWidget {
  const RobotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final hired = c.config.robots.where((r) => s.robotLevel(r.id) > 0).length;
    final normal = c.config.robots.where((r) => !r.special);
    final special = c.config.robots.where((r) => r.special);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.smart_toy, color: OrbitColors.primary),
            title: Text('稼働中のロボット $hired / ${c.config.robots.length} 種'),
            subtitle: Text(c.engine.robotPower(s) > 0
                ? 'ロボット性能 +${fmtPercent(c.engine.robotPower(s))}（転生ボーナス）'
                : 'ロボットは雇用後もレベルアップで性能が上がります'),
          ),
        ),
        const SectionTitle('採掘ロボット'),
        for (final r in normal) _RobotCard(robot: r),
        const SectionTitle('特殊ロボット'),
        for (final r in special) _RobotCard(robot: r),
      ],
    );
  }
}

class _RobotCard extends StatelessWidget {
  const _RobotCard({required this.robot});
  final RobotConfig robot;

  String _effectText(Effect e, double value) {
    final target = e.resource?.label ?? '全資源';
    return switch (e.type) {
      EffectType.production => '$targetの生産 +${fmtPercent(value)}',
      EffectType.offlineEfficiency => '放置効率 +${fmtPercent(value)}',
      _ => '+${fmtPercent(value)}',
    };
  }

  String _unlockText(GameController c) {
    final p = robot.unlock.planet;
    if (p != null && !c.state.unlockedPlanets.contains(p)) {
      return '${c.config.planet(p).name} の開拓で解放';
    }
    if (robot.unlock.entitlement == 'starter_pack') return 'ショップの初心者パックで入手';
    return '未解放';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final lvl = s.robotLevel(robot.id);
    final block = c.engine.robotBlock(s, robot.id);
    final locked = block == UpgradeBlock.locked;
    final cost = c.engine.robotCost(s, robot.id);
    final rp = 1 + c.engine.robotPower(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: OrbitColors.surfaceHigh,
              child: Icon(locked ? Icons.lock_outline : Icons.smart_toy,
                  color: robot.special ? OrbitColors.accent : OrbitColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(robot.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  if (lvl > 0)
                    Text('Lv.$lvl/${robot.maxLevel}',
                        style: const TextStyle(color: OrbitColors.accent, fontSize: 12)),
                ]),
                Text(robot.description,
                    style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                const SizedBox(height: 2),
                if (locked)
                  Text(_unlockText(c), style: const TextStyle(fontSize: 11, color: OrbitColors.textDim))
                else ...[
                  Text(
                    lvl > 0
                        ? '現在：${_effectText(robot.effect, c.engine.robotBonus(s, robot.id))}'
                            '  → 次：${_effectText(robot.effect, robot.effect.perLevel * (lvl + 1) * rp)}'
                        : '雇用すると：${_effectText(robot.effect, robot.effect.perLevel * rp)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  if (block != UpgradeBlock.maxLevel) ...[
                    const SizedBox(height: 4),
                    CostView(cost, s.resources, size: 12),
                  ],
                ],
              ]),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: block == UpgradeBlock.none
                  ? () {
                      tapFeedback(context);
                      c.upgradeRobot(robot.id);
                    }
                  : null,
              child: Text(block == UpgradeBlock.maxLevel
                  ? 'MAX'
                  : locked
                      ? blockLabel(block)
                      : (lvl == 0 ? '雇用' : '強化')),
            ),
          ]),
        ),
      ),
    );
  }
}
