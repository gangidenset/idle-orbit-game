import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/engine/game_engine.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';
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
            subtitle: Text('${fmtRate(c.snap.net[ResourceType.research])}・研究は1つずつ進行し、転生後も引き継がれます'),
          ),
        ),
        const SizedBox(height: 8),
        if (s.activeResearch != null) const _ActiveResearchCard(),
        for (final n in c.config.research)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(builder: (context) {
              final lvl = s.researchLevel(n.id);
              final block = c.engine.researchBlock(s, n.id);
              final cost = n.costForLevel(lvl);
              final secs = c.engine.researchDuration(n.id, lvl);
              final active = s.activeResearch == n.id;
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
                          Row(children: [
                            ResourceAmount(ResourceType.research, cost,
                                size: 12, dim: rp < cost && !active),
                            const SizedBox(width: 10),
                            const Icon(Icons.schedule, size: 12, color: OrbitColors.textDim),
                            const SizedBox(width: 2),
                            Text(secs <= 0 ? '即時' : '所要 ${fmtDuration(Duration(seconds: secs.round()))}',
                                style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                          ]),
                        ],
                      ]),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: block == UpgradeBlock.none ? () => c.doResearch(n.id) : null,
                      child: Text(switch (block) {
                        UpgradeBlock.maxLevel => '完了',
                        _ when active => '研究中',
                        _ => '研究',
                      }),
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

/// The single research in progress: progress, time left and ad speed-up.
class _ActiveResearchCard extends StatelessWidget {
  const _ActiveResearchCard();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final id = s.activeResearch!;
    final n = c.config.researchNode(id);
    final total = c.engine.researchDuration(id, s.researchLevel(id));
    final left = c.engine.researchRemaining(s);
    final mins = c.config.researchAdSpeedupMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: OrbitColors.resource(ResourceType.research), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.science, color: OrbitColors.resource(ResourceType.research)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('研究中：${n.name} Lv.${s.researchLevel(id) + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Text('残り ${fmtClock(Duration(seconds: left.ceil()))}',
                  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total <= 0 ? 1 : (1 - left / total).clamp(0.0, 1.0),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: OrbitColors.outline,
              color: OrbitColors.resource(ResourceType.research),
            ),
            const SizedBox(height: 4),
            const Text('アプリを閉じている間も研究は進みます（放置報酬の上限時間まで）',
                style: TextStyle(fontSize: 11, color: OrbitColors.textDim)),
            if (c.rewardedAvailable) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: c.adInProgress ? null : c.speedUpResearch,
                  icon: const Icon(Icons.fast_forward),
                  label: Text(adLabel(c, '$mins分短縮')),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
