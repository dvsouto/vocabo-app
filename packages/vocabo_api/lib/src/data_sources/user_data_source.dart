import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserDataSource {
  final Dio _dio;

  UserDataSource(this._dio);

  Future<User> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/profile');

    return User.fromJson(response.data!);
  }

  Future<User> updateProfile(Map<String, dynamic> changes) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/user/profile',
      data: changes,
    );

    return User.fromJson(response.data!);
  }

  Future<User> uploadAvatar(String base64Image) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/user/avatar',
      data: {'data': base64Image},
    );

    return User.fromJson(response.data!);
  }

  Future<User> removeAvatar() async {
    final response = await _dio.delete<Map<String, dynamic>>('/user/avatar');

    return User.fromJson(response.data!);
  }

  Future<VerificationDispatch> requestPhoneChange({
    required String phoneCountry,
    required String phoneNumber,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/user/phone/change',
      data: {'phone_country': phoneCountry, 'phone_number': phoneNumber},
    );

    return VerificationDispatch.fromJson(response.data!);
  }

  Future<User> confirmPhoneChange(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/user/phone/confirm',
      data: {'code': code},
    );

    return User.fromJson(response.data!);
  }

  Future<List<UserSession>> listSessions() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/sessions');

    return (response.data!['data'] as List<dynamic>)
        .map((json) => UserSession.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> revokeSession(String id) =>
      _dio.delete<void>('/user/sessions/$id');

  Future<UserPreferences> getPreferences() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/preferences');

    return UserPreferences.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<UserPreferences> updatePreferences(
    Map<String, dynamic> changes,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/user/preferences',
      data: changes,
    );

    return UserPreferences.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
