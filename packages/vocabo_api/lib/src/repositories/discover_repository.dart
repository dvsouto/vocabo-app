import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';

/// Word collections, daily recommendations and the on-demand translation of
/// the words they suggest.
class DiscoverRepository {
  final Dio _dio;

  DiscoverRepository(this._dio);

  Future<List<WordCollection>> getCollections() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/collections',
    );
    return [
      for (final item in response.data!['data'] as List<dynamic>)
        WordCollection.fromJson(item as Map<String, dynamic>),
    ];
  });

  /// The collection with its words (Pro).
  Future<CollectionDetail> getCollection(String id) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/collections/$id',
    );
    return CollectionDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  });

  /// Adds the collection to the collection flashcards (Pro, once).
  Future<CollectionDetail> addCollection(String id) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/discover/collections/$id/add',
      data: const <String, dynamic>{},
    );
    return CollectionDetail.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  });

  /// Translates a suggested word into the native language (Pro). It does
  /// not count as a lookup.
  Future<Vocabulary> translate(String term) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/vocabulary',
      queryParameters: {'term': term},
    );
    return Vocabulary.fromJson(response.data!['data'] as Map<String, dynamic>);
  });

  /// Today's recommendations (Pro), made on the first request of the day.
  Future<Recommendations> getRecommendations({
    required int timezoneOffsetMinutes,
  }) => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/recommendations/today',
      queryParameters: {'timezone_offset_minutes': timezoneOffsetMinutes},
    );
    return Recommendations.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  });
}
