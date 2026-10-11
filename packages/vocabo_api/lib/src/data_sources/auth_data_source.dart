import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/device_info.dart';

/// Sign in providers accepted by the API.
enum SocialAuthProvider { google, apple }

class SignUpRequest {
  const SignUpRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.nativeLanguage,
    this.age,
    this.phoneCountry,
    this.phoneNumber,
  });

  final String name;
  final String email;
  final String password;
  final String nativeLanguage;
  final int? age;
  final String? phoneCountry;

  /// E.164 format.
  final String? phoneNumber;
}

class AuthDataSource {
  final Dio _dio;
  final DeviceInfo _device;

  AuthDataSource(this._dio, {DeviceInfo device = const DeviceInfo()})
    : _device = device;

  Future<AuthToken> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password, 'device': _device.toJson()},
    );

    return AuthToken.fromJson(response.data!);
  }

  Future<AuthToken> register(SignUpRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': request.name,
        'email': request.email,
        'password': request.password,
        'native_language': request.nativeLanguage,
        if (request.age != null) 'age': request.age,
        if (request.phoneNumber != null) ...{
          'phone_country': request.phoneCountry,
          'phone_number': request.phoneNumber,
        },
        'device': _device.toJson(),
      },
    );

    return AuthToken.fromJson(response.data!);
  }

  Future<AuthToken> socialLogin({
    required SocialAuthProvider provider,
    required String idToken,
    String? name,
    String? nativeLanguage,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/${provider.name}',
      data: {
        'id_token': idToken,
        if (name != null) 'name': name,
        if (nativeLanguage != null) 'native_language': nativeLanguage,
        'device': _device.toJson(),
      },
    );

    return AuthToken.fromJson(response.data!);
  }

  Future<void> logout() => _dio.post<void>('/auth/logout');

  Future<VerificationDispatch> sendVerification(
    VerificationChannel channel,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verification/send',
      data: {'channel': channel.apiValue},
    );

    return VerificationDispatch.fromJson(response.data!);
  }

  Future<User> confirmVerification(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/verification/confirm',
      data: {'code': code},
    );

    return User.fromJson(response.data!);
  }
}
