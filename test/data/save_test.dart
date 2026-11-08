import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:idle_orbit/data/save_migrator.dart';
import 'package:idle_orbit/data/save_repository.dart';
import 'package:idle_orbit/game/engine/game_engine.dart';
import 'package:idle_orbit/game/model/resources.dart';

import '../helpers.dart';

void main() {
  final engine = GameEngine(loadBalance());

  test('round trip preserves state', () async {
    final store = MemoryStore();
    final repo = JsonSaveRepository(store);
    final s = engine.newGame(t0)
      ..resources[ResourceType.alloy] = 42
      ..facilities['storage'] = 3
      ..entitlements.add('no_ads')
      ..settings.adFrequency = 'low';
    engine.addBoost(s, source: 'ad', multiplier: 2, minutes: 30, nowMs: t0);
    await repo.save(s);
    final loaded = (await repo.load()).state!;
    expect(loaded.resources[ResourceType.alloy], 42);
    expect(loaded.facilityLevel('storage'), 3);
    expect(loaded.has('no_ads'), isTrue);
    expect(loaded.settings.adFrequency, 'low');
    expect(loaded.boosts.single.multiplier, 2);
    final env = jsonDecode(store.data[JsonSaveRepository.primaryKey]!) as Map;
    expect(env['saveVersion'], currentSaveVersion);
  });

  test('corrupt primary falls back to backup', () async {
    final store = MemoryStore();
    final repo = JsonSaveRepository(store);
    final s = engine.newGame(t0)..resources[ResourceType.ore] = 7;
    await repo.save(s);
    s.resources[ResourceType.ore] = 8;
    await repo.save(s); // backup now holds ore=7
    store.data[JsonSaveRepository.primaryKey] = '{broken';
    final r = await repo.load();
    expect(r.recoveredFromBackup, isTrue);
    expect(r.error, isNotNull);
    expect(r.state!.resources[ResourceType.ore], 7);
  });

  test('migrations run in order', () {
    final m = SaveMigrator(targetVersion: 3, migrations: {
      1: (s) => s..['a'] = 1,
      2: (s) => s..['b'] = (s['a'] as int) + 1,
    });
    final out = m.migrate({'saveVersion': 1, 'state': <String, dynamic>{}});
    expect(out, {'a': 1, 'b': 2});
  });

  test('newer save version is rejected, not silently loaded', () {
    expect(() => SaveMigrator().migrate({'saveVersion': 999, 'state': {}}),
        throwsA(isA<SaveMigrationException>()));
  });
}
