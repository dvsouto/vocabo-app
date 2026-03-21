import 'package:dio/dio.dart';

import 'package:vocabo_api/src/auth/token_storage.dart';
import 'package:vocabo_api/src/client/interceptors/auth_interceptor.dart';
import 'package:vocabo_api/src/client/interceptors/error_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    dio.interceptors.addAll([
      AuthInterceptor(tokenStorage),
      ErrorInterceptor(),
    ]);
  }
}
