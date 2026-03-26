import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/dictionary_data_source.dart';

class DictionaryRepository {
  final DictionaryDataSource _dataSource;

  DictionaryRepository({required DictionaryDataSource dataSource})
      : _dataSource = dataSource;

  Future<List<DictionaryWord>> download({required String lang}) =>
      apiCall(() => _dataSource.download(lang: lang));

  Future<DictionaryVersion> getVersion({required String lang}) =>
      apiCall(() => _dataSource.getVersion(lang: lang));
}
