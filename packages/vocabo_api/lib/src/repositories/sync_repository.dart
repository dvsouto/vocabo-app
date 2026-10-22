import 'package:dio/dio.dart';

import 'package:vocabo_api/src/client/api_call.dart';

/// One change made on any device, from `GET /sync/pull`.
class SyncChange {
  const SyncChange({
    required this.seq,
    required this.entity,
    required this.id,
    required this.deleted,
    this.data,
  });

  factory SyncChange.fromJson(Map<String, dynamic> json) => SyncChange(
    seq: (json['seq'] as num).toInt(),
    entity: json['entity'] as String,
    id: json['id'] as String,
    deleted: json['op'] == 'delete',
    data: json['data'] as Map<String, dynamic>?,
  );

  final int seq;
  final String entity;
  final String id;
  final bool deleted;
  final Map<String, dynamic>? data;
}

class SyncPage {
  const SyncPage({
    required this.changes,
    required this.seq,
    required this.hasMore,
  });

  final List<SyncChange> changes;
  final int seq;
  final bool hasMore;
}

/// A queued write, as sent in `POST /sync/push`.
class SyncOp {
  const SyncOp({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'created_at': createdAt.toUtc().toIso8601String(),
    'payload': payload,
  };
}

enum SyncOpStatus { applied, duplicate, rejected }

class SyncOpResult {
  const SyncOpResult({
    required this.id,
    required this.status,
    this.errorCode,
    this.errorMessage,
    this.data,
  });

  factory SyncOpResult.fromJson(Map<String, dynamic> json) {
    final error = json['error'] as Map<String, dynamic>?;
    return SyncOpResult(
      id: json['id'] as String,
      status: SyncOpStatus.values.byName(json['status'] as String),
      errorCode: error?['code'] as String?,
      errorMessage: error?['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  final String id;
  final SyncOpStatus status;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  /// The server could not process it now (e.g. the AI is down); keep the op.
  bool get retryLater =>
      status == SyncOpStatus.rejected && errorCode == 'retry_later';
}

class SyncPushResponse {
  const SyncPushResponse({required this.results, required this.seq});

  final List<SyncOpResult> results;
  final int seq;
}

/// Offline-first sync: change log, snapshot, outbox push and the manifest
/// of shared data versions.
class SyncRepository {
  SyncRepository(this._dio);

  final Dio _dio;

  Future<int> getSeq() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/sync/state');
    return (response.data!['seq'] as num).toInt();
  });

  /// Everything the account has, for a device that starts empty.
  Future<Map<String, dynamic>> getSnapshot() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/sync/snapshot');
    return response.data!;
  });

  Future<SyncPage> pull({required int since, int limit = 500}) =>
      apiCall(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/sync/pull',
          queryParameters: {'since': since, 'limit': limit},
        );
        final data = response.data!;
        return SyncPage(
          changes: [
            for (final item in data['changes'] as List<dynamic>)
              SyncChange.fromJson(item as Map<String, dynamic>),
          ],
          seq: (data['seq'] as num).toInt(),
          hasMore: data['has_more'] as bool? ?? false,
        );
      });

  Future<SyncPushResponse> push(List<SyncOp> ops) => apiCall(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/push',
      data: {
        'ops': [for (final op in ops) op.toJson()],
      },
    );
    final data = response.data!;
    return SyncPushResponse(
      results: [
        for (final item in data['results'] as List<dynamic>)
          SyncOpResult.fromJson(item as Map<String, dynamic>),
      ],
      seq: (data['seq'] as num).toInt(),
    );
  });

  /// Versions of shared data (collections, config, plans, dictionaries).
  Future<Map<String, dynamic>> getManifest() => apiCall(() async {
    final response = await _dio.get<Map<String, dynamic>>('/sync/manifest');
    return response.data!;
  });
}
