import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class FlashcardsDataSource {
  /// The client always sends `Content-Type: application/json`, and Fastify
  /// rejects that header with an empty body, so body-less POSTs send `{}`.
  static const _emptyJsonBody = <String, dynamic>{};

  final Dio _dio;

  FlashcardsDataSource(this._dio);

  Future<FlashcardConfig> getConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/flashcards/config');

    return FlashcardConfig.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FlashcardStatusSummary> getStatus({
    FlashcardDeck deck = FlashcardDeck.library,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/flashcards/status',
      queryParameters: {'deck': deck.value},
    );

    return FlashcardStatusSummary.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FlashcardSession?> getSession({
    int? size,
    FlashcardDeck deck = FlashcardDeck.library,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/flashcards/session',
      queryParameters: {'deck': deck.value, if (size != null) 'size': size},
    );

    final data = response.data!['data'] as Map<String, dynamic>;
    final session = data['session'];

    if (session is! Map<String, dynamic>) return null;

    return FlashcardSession.fromJson(session);
  }

  Future<FlashcardEvaluationResult> startSession({
    FlashcardDeck deck = FlashcardDeck.library,
    required List<String> flashcardIds,
    required String firstFlashcardId,
    required FlashcardEvaluation evaluation,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/flashcards/session/start',
      data: {
        'deck': deck.value,
        'flashcard_ids': flashcardIds,
        'first_flashcard_id': firstFlashcardId,
        'evaluation': evaluation.value,
      },
    );

    return FlashcardEvaluationResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FlashcardEvaluationResult> evaluateCard({
    required String sessionCardId,
    required FlashcardEvaluation evaluation,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/flashcards/session/cards/$sessionCardId/evaluate',
      data: {'evaluation': evaluation.value},
    );

    return FlashcardEvaluationResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<FlashcardEvaluationResult> archive(String flashcardId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/flashcards/$flashcardId/archive',
      data: _emptyJsonBody,
    );

    return FlashcardEvaluationResult.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<Flashcard> restore(String flashcardId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/flashcards/$flashcardId/restore',
      data: _emptyJsonBody,
    );

    return Flashcard.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<List<Flashcard>> getArchived() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/flashcards/archived',
    );

    return (response.data!['data'] as List<dynamic>)
        .map((item) => Flashcard.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Flashcard?> getByVocabulary(String userVocabularyId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/flashcards/by-vocabulary/$userVocabularyId',
      );

      return Flashcard.fromJson(response.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.error is NotFoundException) {
        return null;
      }
      rethrow;
    }
  }
}
