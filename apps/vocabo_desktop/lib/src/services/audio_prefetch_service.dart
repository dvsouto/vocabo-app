import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_desktop/src/services/audio_cache_service.dart';

class AudioPrefetchService {
  final VocabularyAudioRepository _audioRepository;
  final AudioCacheService _cacheService;
  final Set<String> _prefetching = {};

  AudioPrefetchService({
    required VocabularyAudioRepository audioRepository,
    required AudioCacheService cacheService,
    required String Function() voice,
  })  : _audioRepository = audioRepository,
        _cacheService = cacheService,
        _voice = voice;

  final String Function() _voice;

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
    final voice = _voice();
    // Only prefetch recordings that already exist, so browsing the library
    // never triggers new generation.
    if (!vocab.audioVoices.contains(voice)) return;

    final contentHash = vocab.contentHash!;

    final cached = await _cacheService.getCached(contentHash, voice: voice);
    if (cached != null) return;

    if (_prefetching.contains(contentHash)) return;
    _prefetching.add(contentHash);

    _fetchAndCache(vocab, type.value, voice).ignore();
  }

  Future<void> _fetchAndCache(
    Vocabulary vocab,
    String type,
    String voice,
  ) async {
    final contentHash = vocab.contentHash!;
    try {
      final response = await _audioRepository.getAudio(
        vocabularyId: vocab.id,
        type: type,
        voice: voice,
      );
      await _cacheService.cacheAudio(
        contentHash,
        response.bytes,
        voice: voice,
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
