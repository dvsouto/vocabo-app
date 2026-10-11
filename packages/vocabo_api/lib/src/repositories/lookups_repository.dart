import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/lookups_data_source.dart';

class LookupsRepository {
  final LookupsDataSource _dataSource;

  LookupsRepository({required LookupsDataSource dataSource})
    : _dataSource = dataSource;

  Future<List<TranslationLookup>> list({int? limit}) =>
      apiCall(() => _dataSource.list(limit: limit));

  Future<TranslationLookup> record({
    required String vocabularyId,
    String vocabularyType = 'system',
  }) => apiCall(
    () => _dataSource.record(
      vocabularyId: vocabularyId,
      vocabularyType: vocabularyType,
    ),
  );

  Future<void> delete(String id) => apiCall(() => _dataSource.delete(id));
}
