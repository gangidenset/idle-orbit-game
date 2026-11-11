import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../flame/orbit_scene.dart';
import '../../game/game_controller.dart';
import '../../ui/widgets.dart';
import '../facilities/facility_tile.dart';
import 'base_view_screen.dart';
import 'scene_data.dart';

/// Main screen: the planet scene, boost/free reward actions, the next goal
/// and quick facility upgrades.
class BaseScreen extends StatefulWidget {
  const BaseScreen({super.key, required this.onOpenPlanets});
  final VoidCallback onOpenPlanets;

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  late final OrbitScene _scene;

  @override
  void initState() {
    super.initState();
    final c = context.read<GameController>();
    _scene = OrbitScene(() => buildSceneData(c));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final planet = c.config.planet(s.activePlanet);
    final level = c.engine.levelInfo(s);
    final sceneHeight = (MediaQuery.sizeOf(context).height * 0.34).clamp(200.0, 360.0);

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: SizedBox(
          height: sceneHeight,
          child: Stack(children: [
            Positioned.fill(
              child: Semantics(
                button: true,
                label: '基地を拡大して見る',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => openBaseView(context),
                  child: RepaintBoundary(child: GameWidget(game: _scene)),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 8,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OrbitColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: OrbitColors.outline),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.zoom_in, size: 14, color: OrbitColors.textDim),
                    SizedBox(width: 3),
                    Text('タップで拡大', style: TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 8,
              right: 12,
              child: Row(children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onOpenPlanets,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(planet.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                          planet.activeBonus.isEmpty
                              ? 'タップで惑星一覧'
                              : '滞在ボーナス：${planet.activeBonus.entries.map((e) => '${e.key.label} ×${fmt(e.value)}').join(' ')}',
                          style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                    ]),
                  ),
                ),
                _LevelChip(level: level.$1, progress: level.$2 / level.$3),
              ]),
            ),
            if (c.snap.boost > 1)
              Positioned(
                left: 12,
                bottom: 8,
                child: Chip(
                  avatar: const Icon(Icons.flash_on, color: OrbitColors.accent, size: 18),
                  label: Text('生産 ×${fmt(c.snap.boost)} 中'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverList.list(children: [
          const SizedBox(height: 8),
          const _AdActions(),
          const SizedBox(height: 8),
          _NextGoalCard(onOpenPlanets: widget.onOpenPlanets),
          const SectionTitle('施設', trailing: BuyModeToggle()),
          for (final f in c.config.facilities)
            if (c.engine.isFacilityUnlocked(s, f) || s.facilityLevel(f.id) > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FacilityTile(facility: f, compact: true),
              ),
          _LockedFacilitiesHint(),
          const SizedBox(height: 24),
        ]),
      ),
    ]);
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.progress});
  final int level;
  final double progress;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: '司令官レベル：レベルごとに全生産 +1%',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: OrbitColors.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: OrbitColors.outline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  value: progress, strokeWidth: 3, backgroundColor: OrbitColors.outline),
            ),
            const SizedBox(width: 6),
            Text('Lv.$level', style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ),
      );
}

/// Optional rewarded-ad actions: production boost and free supply.
class _AdActions extends StatelessWidget {
  const _AdActions();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final now = c.nowMs;
    final boostLeft = c.engine.boostRemaining(c.state, 'ad', now);
    final freeCd = c.engine.freeRewardCooldown(c.state, now);
    final canBoost =
        c.rewardedAvailable && c.engine.canExtendAdBoost(c.state, now) && !c.adInProgress;
    final b = c.config.adBoost;

    return Row(children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.flash_on,
          color: OrbitColors.accent,
          title: '生産 ×${fmt(b.multiplier)}',
          subtitle: boostLeft > Duration.zero
              ? '残り ${fmtClock(boostLeft)}（+${fmt(b.minutes)}分）'
              : adLabel(c, '${fmt(b.minutes)}分'),
          onPressed: canBoost
              ? () async {
                  if (await c.activateAdBoost() && context.mounted) {
                    showMessage(context, '生産ブーストが有効になりました！');
                  }
                }
              : null,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ActionButton(
          icon: Icons.card_giftcard,
          color: OrbitColors.success,
          title: '補給物資',
          subtitle: freeCd > Duration.zero
              ? '次まで ${fmtClock(freeCd)}'
              : adLabel(c, '${fmt(c.config.freeRewardProductionMinutes)}分ぶん'),
          onPressed: c.rewardedAvailable && freeCd == Duration.zero && !c.adInProgress
              ? () async {
                  final bag = await c.claimFreeReward();
                  if (bag != null && context.mounted) {
                    await showRewardDialog(context, '補給物資を受け取りました', bag);
                  }
                }
              : null,
        ),
      ),
    ]);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Icon(icon, color: enabled ? color : OrbitColors.textDim),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Shows the next concrete objective — the core retention hook.
class _NextGoalCard extends StatelessWidget {
  const _NextGoalCard({required this.onOpenPlanets});
  final VoidCallback onOpenPlanets;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final next = c.engine.nextLockedPlanet(s);
    if (next == null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.rocket_launch, color: OrbitColors.accent),
          title: const Text('すべての惑星を開拓しました'),
          subtitle: Text('星系ワープで獲得できるポイント: ${c.prestigeSystem.pointsAvailable(s)}'),
        ),
      );
    }
    final cost = next.unlockCost;
    var ratio = 1.0;
    for (final e in cost.nonZero) {
      ratio = ratio < s.resources[e.key] / e.value ? ratio : s.resources[e.key] / e.value;
    }
    final ready = c.engine.canUnlockPlanet(s, next.id);
    return Card(
      color: ready ? OrbitColors.surfaceHigh : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenPlanets,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.public, color: Color(next.colorValue)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(ready ? '${next.name} を開拓できます！' : '次の目標：${next.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (ready) const Icon(Icons.chevron_right),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: OrbitColors.outline,
              color: ready ? OrbitColors.success : OrbitColors.primary,
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              for (final e in cost.nonZero)
                Text('${e.key.label} ${fmt(s.resources[e.key])} / ${fmt(e.value)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: s.resources[e.key] >= e.value
                            ? OrbitColors.success
                            : OrbitColors.textDim)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _LockedFacilitiesHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final locked = c.config.facilities
        .where((f) => !c.engine.isFacilityUnlocked(s, f) && s.facilityLevel(f.id) == 0)
        .toList();
    if (locked.isEmpty) return const SizedBox.shrink();
    final f = locked.first;
    final req = f.requires.entries
        .map((e) => '${c.config.facility(e.key).name} Lv.${e.value}')
        .join('、');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.lock_outline, color: OrbitColors.textDim),
        title: Text('${f.name}（未解放）'),
        subtitle: Text('解放条件：$req'),
      ),
    );
  }
}
