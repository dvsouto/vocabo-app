import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_token.g.dart';

/// A device signed out by this sign in, because of the plan's device limit.
@JsonSerializable()
class RevokedSession extends Equatable {
  const RevokedSession({this.deviceName, this.platform});

  @JsonKey(name: 'device_name')
  final String? deviceName;
  final String? platform;

  factory RevokedSession.fromJson(Map<String, dynamic> json) =>
      _$RevokedSessionFromJson(json);

  Map<String, dynamic> toJson() => _$RevokedSessionToJson(this);

  @override
  List<Object?> get props => [deviceName, platform];
}

@JsonSerializable(explicitToJson: true)
class AuthToken extends Equatable {
  final String token;

  @JsonKey(name: 'revoked_sessions', defaultValue: <RevokedSession>[])
  final List<RevokedSession> revokedSessions;

  const AuthToken({required this.token, this.revokedSessions = const []});

  factory AuthToken.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokenToJson(this);

  @override
  List<Object?> get props => [token, revokedSessions];
}
