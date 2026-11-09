import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../game/game_controller.dart';
import '../game/model/resources.dart';
import '../services/audio/sound_service.dart';

/// Small resource icon + amount.
class ResourceAmount extends StatelessWidget {
  const ResourceAmount(this.type, this.amount,
      {super.key, this.size = 14, this.dim = false, this.prefix = ''});

  final ResourceType type;
  final double amount;
  final double size;
  final bool dim;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    final color = dim ? OrbitColors.danger : null;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(OrbitIcons.resource(type), size: size + 2, color: OrbitColors.resource(type)),
      const SizedBox(width: 2),
      Text('$prefix${fmt(amount)}',
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, color: color)),
    ]);
  }
}

/// Renders a cost; unaffordable parts are shown in red.
class CostView extends StatelessWidget {
  const CostView(this.cost, this.have, {super.key, this.size = 13});
  final ResourceBag cost;
  final ResourceBag have;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 2, children: [
      for (final e in cost.nonZero)
        ResourceAmount(e.key, e.value, size: size, dim: have[e.key] + 1e-9 < e.value),
    ]);
  }
}

/// A list of granted resources, e.g. in reward dialogs.
class RewardList extends StatelessWidget {
  const RewardList(this.bag, {super.key});
  final ResourceBag bag;

  @override
  Widget build(BuildContext context) {
    final items = bag.nonZero.where((e) => e.value > 0).toList();
    if (items.isEmpty) {
      return const Text('獲得できる資源はありません', style: TextStyle(color: OrbitColors.textDim));
    }
    return Column(children: [
      for (final e in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(OrbitIcons.resource(e.key), color: OrbitColors.resource(e.key)),
            const SizedBox(width: 8),
            Text(e.key.label),
            const Spacer(),
            Text('+${fmt(e.value)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
        ),
    ]);
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Row(children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: OrbitColors.textDim)),
          const Spacer(),
          ?trailing,
        ]),
      );
}

/// Badge dot with count for nav items.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Badge(isLabelVisible: count > 0, label: Text('$count'), child: child);
}

/// Shows a modal reward summary.
Future<void> showRewardDialog(BuildContext context, String title, ResourceBag bag,
    {String? note}) {
  playSfx(context, Sfx.reward);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        RewardList(bag),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(color: OrbitColors.textDim, fontSize: 12)),
        ],
      ]),
      actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
    ),
  );
}

/// Haptic + sound feedback for a successful purchase/upgrade tap,
/// respecting the player's settings.
void tapFeedback(BuildContext context) {
  if (context.read<GameController>().state.settings.haptics) {
    HapticFeedback.lightImpact();
  }
  playSfx(context, Sfx.upgrade);
}

void playSfx(BuildContext context, Sfx sfx) => context.read<SoundService>().play(sfx);

void showMessage(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? OrbitColors.danger.withValues(alpha: 0.9) : null,
      duration: const Duration(seconds: 3),
    ));
}

/// Button label for rewarded-ad actions; premium owners skip the ad.
String adLabel(GameController c, String action) => c.rewardedSkips
    ? action
    : (c.rewardedAvailable ? '広告を見て$action' : '広告は利用できません');

/// How many levels an upgrade button buys: 1, 10 or 0 (= max affordable).
class BuyMode extends ValueNotifier<int> {
  BuyMode() : super(1);
}

class BuyModeToggle extends StatelessWidget {
  const BuyModeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<BuyMode>();
    return SegmentedButton<int>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: 1, label: Text('×1')),
        ButtonSegment(value: 10, label: Text('×10')),
        ButtonSegment(value: 0, label: Text('MAX')),
      ],
      selected: {mode.value},
      onSelectionChanged: (v) => mode.value = v.first,
    );
  }
}
