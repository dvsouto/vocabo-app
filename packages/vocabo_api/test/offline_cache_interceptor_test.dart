import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_api/vocabo_api.dart';

class _MemoryCache implements ResponseCache {
  final values = <String, Object?>{};

  @override
  Future<Object?> read(String key) async => values[key];

  @override
  Future<void> write(String key, Object? data) async => values[key] = data;
}

/// Answers every request with [respond], or fails as offline when it
/// returns null.
class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  ResponseBody? Function(RequestOptions options) respond;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    final body = respond(options);
    if (body == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }
    return body;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body) => ResponseBody.fromString(
  body,
  200,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);

void main() {
  late _MemoryCache cache;
  late _Adapter adapter;
  late Dio dio;
  var offline = false;

  setUp(() {
    cache = _MemoryCache();
    adapter = _Adapter((_) => _json('{"plan":"pro"}'));
    offline = false;
    dio = Dio(BaseOptions(baseUrl: 'http://api'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OfflineCacheInterceptor(cache, isOffline: () => offline),
      );
  });

  test('serves the last response when the connection drops', () async {
    await dio.get<Map<String, dynamic>>('/subscriptions/status');
    adapter.respond = (_) => null;

    final response = await dio.get<Map<String, dynamic>>(
      '/subscriptions/status',
    );
    expect(response.data, {'plan': 'pro'});
    expect(
      response.headers.value(OfflineCacheInterceptor.fromCacheHeader),
      '1',
    );
  });

  test('skips the network when the app already knows it is offline', () async {
    await dio.get<Map<String, dynamic>>('/study-notes/today');
    offline = true;
    final before = adapter.calls;

    await dio.get<Map<String, dynamic>>('/study-notes/today');
    expect(adapter.calls, before);
  });

  test('query parameters are part of the key', () async {
    await dio.get<Map<String, dynamic>>(
      '/x',
      queryParameters: {'b': 2, 'a': 1},
    );
    expect(cache.values.keys, ['http:/x?a=1&b=2']);
  });

  test('never caches searches, sync or writes', () async {
    await dio.get<Map<String, dynamic>>('/vocabulary/search');
    await dio.get<Map<String, dynamic>>('/sync/state');
    await dio.post<Map<String, dynamic>>('/user-vocabulary/add');
    expect(cache.values, isEmpty);
  });

  test('without a cached copy the connection error goes through', () async {
    adapter.respond = (_) => null;
    expect(
      () => dio.get<Map<String, dynamic>>('/never-fetched'),
      throwsA(isA<DioException>()),
    );
  });
}
