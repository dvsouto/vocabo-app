import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;
    final data = err.response?.data;
    final message = _extractMessage(data) ?? err.message ?? 'Unknown error';
    final code = _field<String>(data, 'code');
    final details = _extractDetails(data);

    AppException? appException;

    if (statusCode != null) {
      appException = switch (statusCode) {
        400 => BadRequestException(message, code: code, details: details),
        401 => UnauthorizedException(message, code: code, details: details),
        403 => ForbiddenException(message, code: code, details: details),
        404 => NotFoundException(message, code: code, details: details),
        409 => ConflictException(message, code: code, details: details),
        422 => UnprocessableException(message, code: code, details: details),
        429 => TooManyRequestsException(
          message,
          code: code,
          details: details,
          retryAfter: switch (_field<int>(data, 'retry_after')) {
            final int seconds => Duration(seconds: seconds),
            null => null,
          },
        ),
        >= 500 => ServerException(message, code: code, details: details),
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

  String? _extractMessage(dynamic data) => _field<String>(data, 'error');

  T? _field<T>(dynamic data, String key) {
    if (data is Map<String, dynamic>) {
      final value = data[key];
      if (value is T) return value;
    }
    return null;
  }

  Map<String, List<String>> _extractDetails(dynamic data) {
    final details = _field<Map<String, dynamic>>(data, 'details');
    if (details == null) return const {};
    return {
      for (final entry in details.entries)
        if (entry.value is List)
          entry.key: (entry.value as List).whereType<String>().toList(),
    };
  }
}
