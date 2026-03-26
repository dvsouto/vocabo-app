import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/user_vocabulary_data_source.dart';

class UserVocabularyRepository {
  final UserVocabularyDataSource _dataSource;

  UserVocabularyRepository({required UserVocabularyDataSource dataSource})
      : _dataSource = dataSource;

  Future<PaginatedResponse<UserVocabulary>> getAll({
    String? cursor,
    int? limit,
  }) =>
      apiCall(() => _dataSource.getAll(cursor: cursor, limit: limit));

  Future<UserVocabulary> add({required Map<String, dynamic> data}) =>
      apiCall(() => _dataSource.add(data: data));
}
