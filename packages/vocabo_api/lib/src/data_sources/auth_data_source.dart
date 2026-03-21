import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class AuthDataSource {
  final Dio _dio;

  AuthDataSource(this._dio);

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return AuthToken.fromJson(response.data!);
  }
}
