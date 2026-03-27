import 'dart:typed_data';

import 'package:dio/dio.dart';

class VocabularyAudioDataSource {
  final Dio _dio;

  VocabularyAudioDataSource(this._dio);

  Future<Uint8List> getAudio({
    required String vocabularyId,
    required String type,
  }) async {
    final response = await _dio.get<List<int>>(
      '/vocabulary/$vocabularyId/audio',
      queryParameters: {'type': type},
      options: Options(responseType: ResponseType.bytes),
    );

    return Uint8List.fromList(response.data!);
  }
}
