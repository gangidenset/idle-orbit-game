import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../game/game_controller.dart';
import '../../game/model/resources.dart';
import '../../ui/widgets.dart';
import 'facility_tile.dart';

/// Detailed facility management with production overview.
class FacilitiesScreen extends StatelessWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<GameController>();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('生産サマリー', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (final r in ResourceType.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Icon(OrbitIcons.resource(r), size: 16, color: OrbitColors.resource(r)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(r.label, style: const TextStyle(fontSize: 13))),
                    Text('生産 ${fmt(c.snap.gross[r])}  消費 ${fmt(c.snap.consumed[r])}',
                        style: const TextStyle(fontSize: 12, color: OrbitColors.textDim)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 84,
                      child: Text(fmtRate(c.snap.net[r]),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: c.snap.net[r] < 0 ? OrbitColors.danger : null)),
                    ),
                  ]),
                ),
              const SizedBox(height: 4),
              Text('全体倍率：鉱石 ×${fmt(c.mods.production[ResourceType.ore]!)}',
                  style: const TextStyle(fontSize: 11, color: OrbitColors.textDim)),
            ]),
          ),
        ),
        const SectionTitle('施設一覧', trailing: BuyModeToggle()),
        for (final f in c.config.facilities)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FacilityTile(facility: f),
          ),
      ],
    );
  }
}
