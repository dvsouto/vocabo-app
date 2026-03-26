import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserVocabularyDataSource {
  final Dio _dio;

  UserVocabularyDataSource(this._dio);

  Future<PaginatedResponse<UserVocabulary>> getAll({
    String? cursor,
    int? limit,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/user-vocabulary/',
      queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (limit != null) 'limit': limit,
      },
    );

    final data = response.data!['data'] as List<dynamic>;
    final pagination =
        response.data!['pagination'] as Map<String, dynamic>? ?? {};

    final items = data
        .map(
            (item) => UserVocabulary.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedResponse(
      items: items,
      nextCursor: pagination['next_cursor'] as String?,
      hasMore: pagination['has_more'] as bool? ?? false,
    );
  }

  Future<UserVocabulary> add({
    required Map<String, dynamic> data,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/user-vocabulary/add',
      data: data,
    );

    final result = response.data!['data'] as Map<String, dynamic>;

    return UserVocabulary.fromJson({
      ...result['user_vocabulary'] as Map<String, dynamic>,
      'vocabulary': result['vocabulary'],
    });
  }
}
