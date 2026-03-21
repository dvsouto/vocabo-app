import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/vocabulary_data_source.dart';

class VocabularyRepository {
  final VocabularyDataSource _dataSource;

  VocabularyRepository({required VocabularyDataSource dataSource})
      : _dataSource = dataSource;

  Future<Vocabulary> search({
    required String sourceLang,
    required String targetLang,
    required String term,
  }) =>
      apiCall(
        () => _dataSource.search(
          sourceLang: sourceLang,
          targetLang: targetLang,
          term: term,
        ),
      );
}
