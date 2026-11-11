import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import '../../core/logger.dart';

enum Sfx {
  upgrade('upgrade.wav'),
  reward('reward.wav'),
  unlock('unlock.wav'),
  evolve('evolve.wav'),
  warp('warp.wav');

  const Sfx(this.file);
  final String file;
}

/// Sound effects. Playback failures are logged, never thrown into gameplay.
abstract class SoundService {
  Future<void> initialize();
  void play(Sfx sfx);
  void dispose();
}

class SilentSoundService implements SoundService {
  const SilentSoundService();
  @override
  Future<void> initialize() async {}
  @override
  void play(Sfx sfx) {}
  @override
  void dispose() {}
}

/// flame_audio implementation. The frequent upgrade sound uses a small pool
/// so rapid taps don't allocate a new player each time.
class FlameSoundService implements SoundService {
  FlameSoundService({required this.enabled, this.volume = 0.6});

  /// Read on every play so the settings toggle applies immediately.
  final bool Function() enabled;
  final double volume;
  AudioPool? _upgradePool;

  @override
  Future<void> initialize() async {
    try {
      await FlameAudio.audioCache.loadAll([for (final s in Sfx.values) s.file]);
      _upgradePool = await FlameAudio.createPool(Sfx.upgrade.file, maxPlayers: 3);
    } catch (e, st) {
      log.error('Sound init failed; continuing without sound', e, st);
    }
  }

  @override
  void play(Sfx sfx) {
    if (!enabled()) return;
    void onError(Object e, StackTrace st) => log.error('Sound play failed: ${sfx.name}', e, st);
    final pool = _upgradePool;
    if (sfx == Sfx.upgrade && pool != null) {
      unawaited(pool.start(volume: volume * 0.7).then((_) {}, onError: onError));
    } else {
      unawaited(FlameAudio.play(sfx.file, volume: volume).then((_) {}, onError: onError));
    }
  }

  @override
  void dispose() => _upgradePool?.dispose();
}
