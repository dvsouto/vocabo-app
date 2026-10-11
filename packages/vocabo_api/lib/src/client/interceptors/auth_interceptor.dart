import 'package:dio/dio.dart';

import 'package:vocabo_api/src/auth/token_storage.dart';

/// Called when the API rejects the stored token, with the API reason
/// (`session_limit`, `session_revoked`) when there is one.
typedef SessionEndedCallback = void Function(String? reason);

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  final SessionEndedCallback? _onSessionEnded;

  AuthInterceptor(this._tokenStorage, {SessionEndedCallback? onSessionEnded})
    : _onSessionEnded = onSessionEnded;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final sentToken = err.requestOptions.headers.containsKey('Authorization');

    try {
      if (err.response?.statusCode == 401 && sentToken) {
        await _tokenStorage.deleteToken();
        final data = err.response?.data;
        _onSessionEnded?.call(
          data is Map<String, dynamic> ? data['code'] as String? : null,
        );
      }
    } catch (_) {
      // A storage failure must not swallow the original request error.
    } finally {
      handler.next(err);
    }
  }
}
