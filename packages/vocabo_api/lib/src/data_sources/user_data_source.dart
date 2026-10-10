import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserDataSource {
  final Dio _dio;

  UserDataSource(this._dio);

  Future<User> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/profile');

    return User.fromJson(response.data!);
  }

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
