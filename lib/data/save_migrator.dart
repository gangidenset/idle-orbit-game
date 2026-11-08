/// Save data versioning.
///
/// Every save is wrapped as `{"saveVersion": N, "state": {...}}`. When the
/// structure of [GameState] changes, bump [currentSaveVersion] and register a
/// migration from the previous version. Migrations operate on raw JSON so old
/// saves never need old Dart classes.
const currentSaveVersion = 1;

typedef Migration = Map<String, dynamic> Function(Map<String, dynamic> state);

class SaveMigrator {
  SaveMigrator({Map<int, Migration>? migrations, this.targetVersion = currentSaveVersion})
      : migrations = migrations ?? defaultMigrations;

  /// key = version migrated FROM. `0 -> 1` means "pre-versioned save to v1".
  final Map<int, Migration> migrations;
  final int targetVersion;

  static final Map<int, Migration> defaultMigrations = {
    // Example for future use:
    // 1: (s) => s..['newField'] = defaultValue,
  };

  /// Returns the state JSON migrated to [targetVersion].
  /// Throws [SaveMigrationException] for saves from a newer app version or
  /// when a migration step is missing.
  Map<String, dynamic> migrate(Map<String, dynamic> envelope) {
    var version = (envelope['saveVersion'] as num?)?.toInt() ?? 0;
    var state = Map<String, dynamic>.from(
        (envelope['state'] ?? envelope) as Map); // v0 had no envelope

    if (version > targetVersion) {
      throw SaveMigrationException(
          'Save version $version is newer than supported $targetVersion');
    }
    while (version < targetVersion) {
      final m = migrations[version];
      if (m == null) {
        if (version == 0) {
          // v0 -> v1: identical layout, only the envelope was introduced.
          version = 1;
          continue;
        }
        throw SaveMigrationException('No migration from save version $version');
      }
      state = m(state);
      version++;
    }
    return state;
  }

  Map<String, dynamic> wrap(Map<String, dynamic> state) =>
      {'saveVersion': targetVersion, 'state': state};
}

class SaveMigrationException implements Exception {
  SaveMigrationException(this.message);
  final String message;
  @override
  String toString() => 'SaveMigrationException: $message';
}
