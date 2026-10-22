import 'package:dio/dio.dart';

/// Where the last response of each GET is kept, so reads keep working
/// offline. The app backs it with its local database.
abstract interface class ResponseCache {
  Future<Object?> read(String key);
  Future<void> write(String key, Object? data);
}

/// Saves successful JSON GET responses and answers from that copy when the
/// API is unreachable (or the app already knows it is offline). Endpoints
/// with side effects or binary bodies are never cached.
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor(this._cache, {bool Function()? isOffline})
    : _isOffline = isOffline ?? (() => false);

  final ResponseCache _cache;
  final bool Function() _isOffline;

  static const _excluded = [
    '/auth/',
    '/sync/',
    '/vocabulary/search',
    '/dictionary/',
    '/audio',
    '/export',
  ];

  static const fromCacheHeader = 'x-vocabo-from-cache';

  bool _cacheable(RequestOptions options) =>
      options.method == 'GET' &&
      options.responseType == ResponseType.json &&
      !_excluded.any(options.path.contains);

  String _key(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final suffix = query.map((e) => '${e.key}=${e.value}').join('&');
    return 'http:${options.path}${suffix.isEmpty ? '' : '?$suffix'}';
  }

  Response<dynamic> _fromCache(RequestOptions options, Object? data) =>
      Response<dynamic>(
        requestOptions: options,
        data: data,
        statusCode: 200,
        headers: Headers.fromMap({
          fromCacheHeader: ['1'],
        }),
      );

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_cacheable(options) && _isOffline()) {
      final cached = await _cache.read(_key(options));
      if (cached != null) return handler.resolve(_fromCache(options, cached));
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final options = response.requestOptions;
    final status = response.statusCode ?? 0;
    if (_cacheable(options) && status >= 200 && status < 300) {
      await _cache.write(_key(options), response.data);
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final connectionLost =
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout;
    if (connectionLost && _cacheable(err.requestOptions)) {
      final cached = await _cache.read(_key(err.requestOptions));
      if (cached != null) {
        return handler.resolve(_fromCache(err.requestOptions, cached));
      }
    }
    handler.next(err);
  }
}
