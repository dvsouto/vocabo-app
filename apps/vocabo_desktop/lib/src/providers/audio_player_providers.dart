import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/services/audio_cache_service.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';

final audioCacheServiceProvider = Provider<AudioCacheService>((ref) {
  return AudioCacheService();
});

final audioPlayerServiceProvider =
    ChangeNotifierProvider<AudioPlayerService>((ref) {
  final api = ref.watch(apiClientProvider);
  final cache = ref.watch(audioCacheServiceProvider);

  return AudioPlayerService(
    audioRepository: api.vocabularyAudio,
    cacheService: cache,
  );
});

final audioPlayerStateProvider = Provider<AudioPlayerState>((ref) {
  return ref.watch(audioPlayerServiceProvider).state;
});
