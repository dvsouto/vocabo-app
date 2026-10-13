import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/flashcards_data_source.dart';

class FlashcardsRepository {
  final FlashcardsDataSource _dataSource;

  FlashcardsRepository({required FlashcardsDataSource dataSource})
    : _dataSource = dataSource;

  Future<FlashcardConfig> getConfig() => apiCall(() => _dataSource.getConfig());

  Future<FlashcardStatusSummary> getStatus({
    FlashcardDeck deck = FlashcardDeck.library,
  }) => apiCall(() => _dataSource.getStatus(deck: deck));

  /// Pass [size] for a shorter deck; an in-progress session is always
  /// resumed as is.
  Future<FlashcardSession?> getSession({
    int? size,
    FlashcardDeck deck = FlashcardDeck.library,
  }) => apiCall(() => _dataSource.getSession(size: size, deck: deck));

  Future<FlashcardEvaluationResult> startSession({
    FlashcardDeck deck = FlashcardDeck.library,
    required List<String> flashcardIds,
    required String firstFlashcardId,
    required FlashcardEvaluation evaluation,
  }) => apiCall(
    () => _dataSource.startSession(
      deck: deck,
      flashcardIds: flashcardIds,
      firstFlashcardId: firstFlashcardId,
      evaluation: evaluation,
    ),
  );

  Future<FlashcardEvaluationResult> evaluateCard({
    required String sessionCardId,
    required FlashcardEvaluation evaluation,
  }) => apiCall(
    () => _dataSource.evaluateCard(
      sessionCardId: sessionCardId,
      evaluation: evaluation,
    ),
  );

  Future<FlashcardEvaluationResult> archive(String flashcardId) =>
      apiCall(() => _dataSource.archive(flashcardId));

  Future<Flashcard> restore(String flashcardId) =>
      apiCall(() => _dataSource.restore(flashcardId));

  Future<List<Flashcard>> getArchived() =>
      apiCall(() => _dataSource.getArchived());

  Future<Flashcard?> getByVocabulary(String userVocabularyId) =>
      apiCall(() => _dataSource.getByVocabulary(userVocabularyId));
}
