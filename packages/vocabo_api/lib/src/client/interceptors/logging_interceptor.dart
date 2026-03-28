import 'dart:developer' as developer;

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln('──── Request ────')
      ..writeln('${options.method} ${options.uri}')
      ..writeln('Headers: ${options.headers}');

    if (options.data != null) {
      buffer.writeln('Body: ${options.data}');
    }

    if (options.queryParameters.isNotEmpty) {
      buffer.writeln('Query: ${options.queryParameters}');
    }

    developer.log(buffer.toString(), name: 'HTTP');

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln('──── Response ────')
      ..writeln(
        '${response.requestOptions.method} ${response.requestOptions.uri}',
      )
      ..writeln('Status: ${response.statusCode}')
      ..writeln('Data: ${response.data}');

    developer.log(buffer.toString(), name: 'HTTP');

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buffer = StringBuffer()
      ..writeln('──── Error ────')
      ..writeln('${err.requestOptions.method} ${err.requestOptions.uri}')
      ..writeln('Type: ${err.type}')
      ..writeln('Message: ${err.message}');

    if (err.response != null) {
      buffer
        ..writeln('Status: ${err.response?.statusCode}')
        ..writeln('Data: ${err.response?.data}');
    }

    developer.log(buffer.toString(), name: 'HTTP', level: 900);

    handler.next(err);
  }
}
