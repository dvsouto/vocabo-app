import 'dart:typed_data';

import 'package:dio/dio.dart';

class AudioResponse {
  final Uint8List bytes;
  final String? contentType;

  AudioResponse({required this.bytes, this.contentType});
}

class VocabularyAudioDataSource {
  final Dio _dio;

  VocabularyAudioDataSource(this._dio);

  Future<AudioResponse> getAudio({
    required String vocabularyId,
    required String type,
  }) async {
    final response = await _dio.get<List<int>>(
      '/vocabulary/$vocabularyId/audio',
      queryParameters: {'type': type},
      options: Options(responseType: ResponseType.bytes),
    );

    return AudioResponse(
      bytes: Uint8List.fromList(response.data!),
      contentType: response.headers.value('content-type'),
    );
  }
}
