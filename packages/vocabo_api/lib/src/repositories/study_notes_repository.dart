import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';

class StudyNotesRepository {
  final Dio _dio;

  StudyNotesRepository(this._dio);

  /// Today's Study Note (Pro), written on the first request of the day.
  Future<StudyNote> getToday({required int timezoneOffsetMinutes}) => apiCall(
    () async {
      final response = await _dio.get<Map<String, dynamic>>(
        '/study-notes/today',
        queryParameters: {'timezone_offset_minutes': timezoneOffsetMinutes},
      );
      return StudyNote.fromJson(response.data!['data'] as Map<String, dynamic>);
    },
  );
}
