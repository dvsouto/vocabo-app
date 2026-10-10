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
      await _prefetchOne(uv.vocabulary, uv.vocabularyType);
    }
  }

  Future<void> prefetchFlashcards(List<Flashcard> flashcards) async {
    for (final flashcard in flashcards) {
      await _prefetchOne(flashcard.vocabulary, flashcard.vocabularyType);
    }
  }

  Future<void> _prefetchOne(Vocabulary? vocab, VocabularyType type) async {
    if (vocab == null) return;
    if (vocab.contentHash == null || vocab.contentHash!.isEmpty) return;
    if (vocab.audioStatus != 'done') return;

    final contentHash = vocab.contentHash!;

    final cached = await _cacheService.getCached(contentHash);
    if (cached != null) return;

    if (_prefetching.contains(contentHash)) return;
    _prefetching.add(contentHash);

    _fetchAndCache(vocab, type.value).ignore();
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
      appLogger.debug('AudioPrefetch: cached audio for ${vocab.term}');
    } catch (e) {
      appLogger.error('AudioPrefetch failed for ${vocab.term}', e);
    } finally {
      _prefetching.remove(contentHash);
    }
  }
}
