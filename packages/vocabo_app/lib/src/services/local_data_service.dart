import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vocabo_app/src/providers/audio_player_providers.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

/// Removes everything cached for the signed-in account, so a device that
/// was signed out elsewhere keeps nothing of the library.
final localDataServiceProvider = Provider<LocalDataService>(
  (ref) => LocalDataService(ref),
);

class LocalDataService {
  LocalDataService(this._ref);

  final Ref _ref;

  Future<void> clearAccountData() async {
    await _ref.read(syncEngineProvider.notifier).reset();
    await _ref.read(audioCacheServiceProvider).clear();
  }
}
