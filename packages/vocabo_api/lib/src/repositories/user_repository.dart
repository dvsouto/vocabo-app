import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/user_data_source.dart';

/// Sentinel that lets [UserRepository.updateProfile] tell "clear the age"
/// apart from "leave it unchanged".
const _unchanged = Object();

class UserRepository {
  final UserDataSource _dataSource;

  UserRepository({required UserDataSource dataSource})
    : _dataSource = dataSource;

  Future<User> getProfile() => apiCall(() => _dataSource.getProfile());

  /// The email can't be changed, and the phone goes through
  /// [requestPhoneChange] so it is verified first.
  Future<User> updateProfile({
    String? name,
    Object? age = _unchanged,
    String? nativeLanguage,
  }) => apiCall(
    () => _dataSource.updateProfile({
      if (name != null) 'name': name,
      if (!identical(age, _unchanged)) 'age': age as int?,
      if (nativeLanguage != null) 'native_language': nativeLanguage,
    }),
  );

  /// [base64Image] is a PNG or JPEG up to 2 MB.
  Future<User> uploadAvatar(String base64Image) =>
      apiCall(() => _dataSource.uploadAvatar(base64Image));

  Future<User> removeAvatar() => apiCall(_dataSource.removeAvatar);

  Future<VerificationDispatch> requestPhoneChange({
    required String phoneCountry,
    required String phoneNumber,
  }) => apiCall(
    () => _dataSource.requestPhoneChange(
      phoneCountry: phoneCountry,
      phoneNumber: phoneNumber,
    ),
  );

  Future<User> confirmPhoneChange(String code) =>
      apiCall(() => _dataSource.confirmPhoneChange(code));

  Future<List<UserSession>> listSessions() => apiCall(_dataSource.listSessions);

  Future<void> revokeSession(String id) =>
      apiCall(() => _dataSource.revokeSession(id));

  Future<UserPreferences> getPreferences() =>
      apiCall(() => _dataSource.getPreferences());

  Future<UserPreferences> updatePreferences({
    bool? showTranslations,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
  }) => apiCall(
    () => _dataSource.updatePreferences({
      if (showTranslations != null) 'show_translations': showTranslations,
      if (dailyReminderEnabled != null)
        'daily_reminder_enabled': dailyReminderEnabled,
      if (dailyReminderTime != null) 'daily_reminder_time': dailyReminderTime,
    }),
  );
}
