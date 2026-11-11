import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/engine/game_engine.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';
import '../../ui/hold_repeat_button.dart';
import '../../ui/widgets.dart';

class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    if (!c.engine.isResearchAvailable(s)) {
      final lab = c.config.facility('research_lab');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.lock_outline, size: 48, color: OrbitColors.textDim),
            const SizedBox(height: 12),
            const Text('研究はまだ利用できません', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '「${lab.name}」を建設すると研究ポイントが生産され、'
              '恒久的な技術強化を研究できるようになります。',
              textAlign: TextAlign.center,
              style: const TextStyle(color: OrbitColors.textDim),
            ),
          ]),
        ),
      );
    }
    final rp = s.resources[ResourceType.research];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            leading: Icon(OrbitIcons.resource(ResourceType.research),
                color: OrbitColors.resource(ResourceType.research)),
            title: Text('研究ポイント ${fmt(rp)}'),
            subtitle: Text('${fmtRate(c.snap.net[ResourceType.research])}・研究は転生でリセットされます'),
          ),
        ),
        const SizedBox(height: 8),
        for (final n in c.config.research)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final lvl = s.researchLevel(n.id);
              final block = c.engine.researchBlock(s, n.id);
              final cost = n.costForLevel(lvl);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text('Lv.$lvl/${n.maxLevel}',
                              style: const TextStyle(color: OrbitColors.accent, fontSize: 12)),
                        ]),
                        Text(n.description,
                            style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: lvl / n.maxLevel,
                          minHeight: 3,
                          backgroundColor: OrbitColors.outline,
                        ),
                        if (block != UpgradeBlock.maxLevel) ...[
                          const SizedBox(height: 4),
                          ResourceAmount(ResourceType.research, cost,
                              size: 12, dim: rp < cost),
                        ],
                      ]),
                    ),
                    const SizedBox(width: 8),
                    HoldRepeatButton(
                      onStep: block == UpgradeBlock.none ? () => c.doResearch(n.id) : null,
                      child: Text(block == UpgradeBlock.maxLevel ? '完了' : '研究'),
                    ),
                  ]),
                ),
              );
            }),
          ),
      ],
    );
  }
}
