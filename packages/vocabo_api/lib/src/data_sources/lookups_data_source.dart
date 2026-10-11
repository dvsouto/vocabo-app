import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class LookupsDataSource {
  final Dio _dio;

  LookupsDataSource(this._dio);

  Future<List<TranslationLookup>> list({int? limit}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/lookups',
      queryParameters: {if (limit != null) 'limit': limit},
    );

    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((item) => TranslationLookup.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TranslationLookup> record({
    required String vocabularyId,
    String vocabularyType = 'system',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/lookups',
      data: {'vocabulary_id': vocabularyId, 'vocabulary_type': vocabularyType},
    );

    return TranslationLookup.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/lookups/$id');
  }
}
