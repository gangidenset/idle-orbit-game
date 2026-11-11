import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/config/balance_config.dart';
import '../../game/engine/game_engine.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';
import '../../ui/hold_repeat_button.dart';
import '../../ui/widgets.dart';

/// A facility row with level, output and an upgrade button that follows the
/// global [BuyMode] (×1 / ×10 / MAX).
class FacilityTile extends StatelessWidget {
  const FacilityTile({super.key, required this.facility, this.compact = false});

  final FacilityConfig facility;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final mode = context.watch<BuyMode>().value;
    final s = c.state;
    final e = c.engine;
    final id = facility.id;
    final lvl = s.facilityLevel(id);
    final unlocked = e.isFacilityUnlocked(s, facility);
    final out = c.snap.of(id);

    var n = mode == 0 ? e.affordableFacilityLevels(s, id) : mode;
    if (n == 0) n = 1;
    final cost = n == 1 ? e.facilityCost(s, id, c.mods) : e.facilityCostMany(s, id, n);
    final canBuy = unlocked && s.resources.covers(cost);
    final isStorage = id == c.config.storage.facilityId;
    final v = c.visuals;
    final tier = v.tierFor(lvl);
    final nextTierAt = v.nextTierLevel(lvl);
    final tierLevels = c.config.visuals.tierLevels;
    final tierStart = tier == 0 ? 0 : tierLevels[tier - 1];
    final nextTierName = nextTierAt == null || facility.tierNames.isEmpty
        ? null
        : facility.tierNames[tier]; // tier is 0-based index of the next one
    final nextBoost = nextTierAt == null
        ? 1.0
        : e.milestoneMultiplier(nextTierAt) / e.milestoneMultiplier(nextTierAt - 1);
    final tierProgress = nextTierAt == null
        ? 1.0
        : ((lvl - tierStart) / (nextTierAt - tierStart)).clamp(0.0, 1.0);
    final color = lvl > 0 ? OrbitColors.facility(facility.icon) : OrbitColors.textDim;

    final outputLine = isStorage
        ? '上限 ${[
            for (final r in [ResourceType.ore, ResourceType.energy, ResourceType.alloy])
              '${r.label} ${fmt(e.storageCap(s, r, c.mods))}',
          ].join(' / ')}'
        : out == null
            ? (lvl == 0 ? '未建設' : '稼働停止')
            : [
                for (final o in out.output.nonZero) '${o.key.label} ${fmtRate(o.value * out.efficiency)}',
                if (out.efficiency < 0.999) '稼働率 ${fmtPercent(out.efficiency)}',
              ].join('  ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OrbitColors.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(OrbitIcons.facility(facility.icon), color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(lvl > 0 ? v.tierName(facility, lvl) : facility.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 6),
                Text('Lv.$lvl', style: const TextStyle(color: OrbitColors.accent, fontSize: 13)),
                if (tier > 0) ...[
                  const SizedBox(width: 4),
                  _TierStars(tier: tier, max: v.maxTier(), color: color),
                ],
              ]),
              if (lvl > 0 && v.tierName(facility, lvl) != facility.name)
                Text(facility.name,
                    style: const TextStyle(fontSize: 10, color: OrbitColors.textDim)),
              const SizedBox(height: 2),
              Text(outputLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      color: out != null && out.efficiency < 0.5
                          ? OrbitColors.danger
                          : OrbitColors.textDim)),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(facility.description,
                    style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),

                if (facility.isConverter)
                  Text(
                      '消費：${facility.consumes.nonZero.map((x) => '${x.key.label} ${fmt(x.value * (lvl == 0 ? 1 : lvl))}/秒').join(' ')}',
                      style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
              ],
              if (lvl > 0 && nextTierAt != null) ...[
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: tierProgress,
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: OrbitColors.outline,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  'Lv.$nextTierAt で【${nextTierName ?? '進化'}】に進化'
                  '${!isStorage && nextBoost > 1 ? '・生産×${fmt(nextBoost)}' : ''}',
                  style: const TextStyle(fontSize: 11, color: OrbitColors.accent),
                ),
              ],
              const SizedBox(height: 4),
              if (unlocked) CostView(cost, s.resources, size: 12),
              if (!unlocked)
                Text(
                    '解放条件：${facility.requires.entries.map((r) => '${c.config.facility(r.key).name} Lv.${r.value}').join('、')}',
                    style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
            ]),
          ),
          const SizedBox(width: 8),
          HoldRepeatButton(
            // Each step re-reads the state, so MAX keeps buying what's
            // affordable as resources change while the button is held.
            onStep: canBuy
                ? () {
                    final k = mode == 0 ? e.affordableFacilityLevels(c.state, id) : mode;
                    return k > 0 && c.upgradeFacility(id, count: k) > 0;
                  }
                : null,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(lvl == 0 ? '建設' : '強化'),
              if (n > 1) Text('×$n', style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Short label for an upgrade block reason.
String blockLabel(UpgradeBlock b) => switch (b) {
      UpgradeBlock.none => '',
      UpgradeBlock.maxLevel => '最大レベル',
      UpgradeBlock.locked => '未解放',
      UpgradeBlock.insufficient => '資源不足',
    };

class _TierStars extends StatelessWidget {
  const _TierStars({required this.tier, required this.max, required this.color});
  final int tier;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < max; i++)
          Icon(Icons.star, size: 10, color: i < tier ? color : OrbitColors.outline),
      ]);
}
