import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserVocabularyDataSource {
  final Dio _dio;

  UserVocabularyDataSource(this._dio);

  Future<List<UserVocabulary>> getAll() async {
    final response = await _dio.get<Map<String, dynamic>>('/user-vocabulary/');

    final data = response.data!['data'] as List<dynamic>;

    return data
        .map((item) =>
            UserVocabulary.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
