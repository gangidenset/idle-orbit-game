import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../../ui/widgets.dart';

class PlanetsScreen extends StatelessWidget {
  const PlanetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    final s = c.state;
    final next = c.engine.nextLockedPlanet(s);
    return Scaffold(
      appBar: AppBar(title: const Text('惑星開拓')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text(
            '惑星を開拓すると全資源の生産量が恒久的に上がります（転生でリセット）。'
            '滞在する惑星を切り替えると、その惑星の滞在ボーナスが得られます。',
            style: TextStyle(fontSize: 12, color: OrbitColors.textDim),
          ),
          const SizedBox(height: 12),
          for (final p in c.config.planets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Builder(builder: (context) {
                final unlocked = s.unlockedPlanets.contains(p.id);
                final active = s.activePlanet == p.id;
                final isNext = next?.id == p.id;
                final canUnlock = c.engine.canUnlockPlanet(s, p.id);
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                        color: active ? Color(p.colorValue) : OrbitColors.outline,
                        width: active ? 2 : 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: unlocked || isNext
                              ? RadialGradient(
                                  center: const Alignment(-0.4, -0.4),
                                  colors: [Colors.white70, Color(p.colorValue), Colors.black87],
                                  stops: const [0, 0.45, 1],
                                )
                              : null,
                          color: unlocked || isNext ? null : OrbitColors.surfaceHigh,
                        ),
                        child: unlocked || isNext
                            ? null
                            : const Icon(Icons.question_mark, color: OrbitColors.textDim),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(unlocked || isNext ? p.name : '？？？',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (unlocked || isNext)
                            Text(p.description,
                                style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
                          if (p.permanentMultiplier > 1 && (unlocked || isNext))
                            Text('開拓ボーナス：全生産 ×${fmt(p.permanentMultiplier)}',
                                style: const TextStyle(fontSize: 11, color: OrbitColors.accent)),
                          if (isNext) ...[
                            const SizedBox(height: 4),
                            CostView(p.unlockCost, s.resources, size: 12),
                          ],
                        ]),
                      ),
                      const SizedBox(width: 8),
                      if (unlocked)
                        active
                            ? const Chip(label: Text('滞在中'), visualDensity: VisualDensity.compact)
                            : OutlinedButton(
                                onPressed: () => c.setActivePlanet(p.id),
                                child: const Text('移動'),
                              )
                      else if (isNext)
                        FilledButton(
                          onPressed: canUnlock
                              ? () {
                                  tapFeedback(context);
                                  c.unlockPlanet(p.id);
                                }
                              : null,
                          child: const Text('開拓'),
                        ),
                    ]),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
