import 'package:equatable/equatable.dart';

/// A device signed in to the account.
class UserSession extends Equatable {
  final String id;

  /// `password`, `google` or `apple`.
  final String authMethod;
  final String? deviceName;
  final String? platform;
  final String? appVersion;
  final String? ip;
  final DateTime lastSeenAt;
  final DateTime createdAt;

  /// True for the session making the request.
  final bool current;

  const UserSession({
    required this.id,
    required this.authMethod,
    this.deviceName,
    this.platform,
    this.appVersion,
    this.ip,
    required this.lastSeenAt,
    required this.createdAt,
    this.current = false,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id'] as String,
      authMethod: json['auth_method'] as String,
      deviceName: json['device_name'] as String?,
      platform: json['platform'] as String?,
      appVersion: json['app_version'] as String?,
      ip: json['ip'] as String?,
      lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      current: json['current'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    authMethod,
    deviceName,
    platform,
    appVersion,
    ip,
    lastSeenAt,
    createdAt,
    current,
  ];
}
