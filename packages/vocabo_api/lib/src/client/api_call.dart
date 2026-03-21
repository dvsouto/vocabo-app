import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

/// Executes an API call and unwraps [DioException] into [AppException].
Future<T> apiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    rethrow;
  }
}
