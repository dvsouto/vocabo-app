import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/user_data_source.dart';

class UserRepository {
  final UserDataSource _dataSource;

  UserRepository({required UserDataSource dataSource})
      : _dataSource = dataSource;

  Future<User> getProfile() => apiCall(() => _dataSource.getProfile());
}
