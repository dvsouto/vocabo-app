import 'package:flutter/foundation.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_desktop/src/services/audio_cache_service.dart';

class AudioPrefetchService {
  final VocabularyAudioRepository _audioRepository;
  final AudioCacheService _cacheService;
  final Set<String> _prefetching = {};

  AudioPrefetchService({
    required VocabularyAudioRepository audioRepository,
    required AudioCacheService cacheService,
  })  : _audioRepository = audioRepository,
        _cacheService = cacheService;

  Future<void> prefetch(List<UserVocabulary> vocabularies) async {
    for (final uv in vocabularies) {
      final vocab = uv.vocabulary;
      if (vocab == null) continue;
      if (vocab.contentHash == null || vocab.contentHash!.isEmpty) continue;
      if (vocab.audioStatus != 'done') continue;

      final contentHash = vocab.contentHash!;

      final cached = await _cacheService.getCached(contentHash);
      if (cached != null) continue;

      if (_prefetching.contains(contentHash)) continue;
      _prefetching.add(contentHash);

      _fetchAndCache(vocab, uv.vocabularyType.value).ignore();
    }
  }

  Future<void> _fetchAndCache(Vocabulary vocab, String type) async {
    final contentHash = vocab.contentHash!;
    try {
      final response = await _audioRepository.getAudio(
        vocabularyId: vocab.id,
        type: type,
      );
      await _cacheService.cacheAudio(
        contentHash,
        response.bytes,
        contentType: response.contentType,
      );
      debugPrint('[AudioPrefetch] Cached audio for: ${vocab.term}');
    } catch (e) {
      debugPrint('[AudioPrefetch] Failed for ${vocab.term}: $e');
    } finally {
      _prefetching.remove(contentHash);
    }
  }
}
