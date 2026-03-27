import 'dart:typed_data';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/vocabulary_audio_data_source.dart';

class VocabularyAudioRepository {
  final VocabularyAudioDataSource _dataSource;

  VocabularyAudioRepository({required VocabularyAudioDataSource dataSource})
      : _dataSource = dataSource;

  Future<Uint8List> getAudio({
    required String vocabularyId,
    required String type,
  }) =>
      apiCall(
        () => _dataSource.getAudio(
          vocabularyId: vocabularyId,
          type: type,
        ),
      );
}
