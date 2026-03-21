import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class VocabularyDataSource {
  final Dio _dio;

  VocabularyDataSource(this._dio);

  Future<Vocabulary> search({
    required String sourceLang,
    required String targetLang,
    required String term,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vocabulary/search',
      queryParameters: {
        'source_lang': sourceLang,
        'target_lang': targetLang,
        'term': term,
      },
    );

    return Vocabulary.fromJson(response.data!['data'] as Map<String, dynamic>);
  }
}
