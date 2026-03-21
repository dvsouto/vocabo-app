import 'package:dio/dio.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserDataSource {
  final Dio _dio;

  UserDataSource(this._dio);

  Future<User> getProfile() async {
    final response = await _dio.get<Map<String, dynamic>>('/user/profile');

    return User.fromJson(response.data!);
  }
}
