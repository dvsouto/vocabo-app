import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/user_vocabulary_data_source.dart';

class UserVocabularyRepository {
  final UserVocabularyDataSource _dataSource;

  UserVocabularyRepository({required UserVocabularyDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<UserVocabulary>> getAll() =>
      apiCall(() => _dataSource.getAll());
}
