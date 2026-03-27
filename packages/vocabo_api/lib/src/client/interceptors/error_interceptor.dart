import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final message =
        _extractMessage(err.response?.data) ?? err.message ?? 'Unknown error';

    AppException? appException;

    if (statusCode != null) {
      appException = switch (statusCode) {
        400 => BadRequestException(message),
        401 => UnauthorizedException(message),
        404 => NotFoundException(message),
        409 => ConflictException(message),
        422 => UnprocessableException(message),
        >= 500 => ServerException(message),
        _ => null,
      };
    }

    appException ??= _mapConnectionError(err, message);

    if (appException != null) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          type: err.type,
          error: appException,
        ),
      );
      return;
    }

    handler.next(err);
  }

  AppException? _mapConnectionError(DioException err, String message) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkException(message);
    }
    return ServerException(message);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['error'] as String?;
    }
    return null;
  }
}
