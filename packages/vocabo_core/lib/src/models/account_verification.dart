import 'package:equatable/equatable.dart';

enum VerificationChannel {
  email,
  phone;

  String get apiValue => name;

  static VerificationChannel fromJson(String value) =>
      value == 'phone' ? VerificationChannel.phone : VerificationChannel.email;
}

/// Result of asking the API to send a confirmation code.
class VerificationDispatch extends Equatable {
  final VerificationChannel channel;

  /// Masked destination, e.g. `da***@gmail.com`.
  final String sentTo;
  final DateTime expiresAt;
  final Duration retryAfter;

  /// Returned by non-production APIs while delivery is simulated.
  final String? debugCode;

  const VerificationDispatch({
    required this.channel,
    required this.sentTo,
    required this.expiresAt,
    required this.retryAfter,
    this.debugCode,
  });

  factory VerificationDispatch.fromJson(Map<String, dynamic> json) {
    return VerificationDispatch(
      channel: VerificationChannel.fromJson(json['channel'] as String),
      sentTo: json['sent_to'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      retryAfter: Duration(seconds: json['retry_after'] as int? ?? 30),
      debugCode: json['debug_code'] as String?,
    );
  }

  @override
  List<Object?> get props => [
    channel,
    sentTo,
    expiresAt,
    retryAfter,
    debugCode,
  ];
}
