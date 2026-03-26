import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class DictionaryDataSource {
  final Dio _dio;

  DictionaryDataSource(this._dio);

  Future<List<DictionaryWord>> download({required String lang}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/dictionary/download',
      queryParameters: {'lang': lang},
    );

    final data = response.data!['data'] as List<dynamic>;
    return data
        .map((item) =>
            DictionaryWord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DictionaryVersion> getVersion({required String lang}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/dictionary/version',
      queryParameters: {'lang': lang},
    );

    return DictionaryVersion.fromJson(
        response.data!['data'] as Map<String, dynamic>);
  }
}
