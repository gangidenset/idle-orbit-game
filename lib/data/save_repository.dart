import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/logger.dart';
import '../game/model/game_state.dart';
import 'save_migrator.dart';

/// Result of loading a save.
class LoadResult {
  LoadResult(this.state, {this.recoveredFromBackup = false, this.error});

  /// Null when there is no usable save (new player).
  final GameState? state;
  final bool recoveredFromBackup;

  /// Non-null when the primary save was unreadable. Surfaced to the UI.
  final Object? error;
}

abstract class SaveRepository {
  Future<LoadResult> load();
  Future<void> save(GameState state);
  Future<void> clear();
}

/// Stores the save as a single JSON document in key-value storage.
///
/// The save is small (a few KB), written every ~15 s, and always read and
/// written as a whole, so a JSON document is simpler and more robust than a
/// relational schema. The previous good save is kept as a backup to recover
/// from corruption. The [KeyValueStore] abstraction allows swapping in
/// SQLite/files later without touching the game.
class JsonSaveRepository implements SaveRepository {
  JsonSaveRepository(this.store, {SaveMigrator? migrator})
      : migrator = migrator ?? SaveMigrator();

  static const primaryKey = 'idle_orbit_save';
  static const backupKey = 'idle_orbit_save_backup';

  final KeyValueStore store;
  final SaveMigrator migrator;

  @override
  Future<LoadResult> load() async {
    final primary = await store.read(primaryKey);
    if (primary == null) return LoadResult(null);
    try {
      return LoadResult(_decode(primary));
    } catch (e, st) {
      log.error('Primary save unreadable, trying backup', e, st);
      final backup = await store.read(backupKey);
      if (backup != null) {
        try {
          return LoadResult(_decode(backup), recoveredFromBackup: true, error: e);
        } catch (e2, st2) {
          log.error('Backup save unreadable', e2, st2);
        }
      }
      // Do not overwrite the broken save automatically: keep it for support.
      await store.write('${primaryKey}_corrupt_${DateTime.now().millisecondsSinceEpoch}',
          primary);
      return LoadResult(null, error: e);
    }
  }

  GameState _decode(String raw) {
    final env = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return GameState.fromJson(migrator.migrate(env));
  }

  @override
  Future<void> save(GameState state) async {
    final encoded = jsonEncode(migrator.wrap(state.toJson()));
    final previous = await store.read(primaryKey);
    if (previous != null) await store.write(backupKey, previous);
    await store.write(primaryKey, encoded);
  }

  @override
  Future<void> clear() async {
    await store.remove(primaryKey);
    await store.remove(backupKey);
  }
}

abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this.prefs);
  final SharedPreferences prefs;

  @override
  Future<String?> read(String key) async => prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final ok = await prefs.setString(key, value);
    if (!ok) throw StateError('Failed to write "$key"');
  }

  @override
  Future<void> remove(String key) async => prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
}
