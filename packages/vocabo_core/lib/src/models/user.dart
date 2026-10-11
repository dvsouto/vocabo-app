import 'package:equatable/equatable.dart';

enum UserPlan {
  free,
  pro;

  static UserPlan fromJson(String? value) =>
      value == 'pro' ? UserPlan.pro : UserPlan.free;

  String get label => switch (this) {
    UserPlan.free => 'FREE',
    UserPlan.pro => 'PRO',
  };
}

class User extends Equatable {
  final String id;
  final String name;
  final String email;

  /// ISO 3166-1 alpha-2 code of the phone number's country.
  final String? phoneCountry;

  /// E.164 format, e.g. `+5511987654321`.
  final String? phoneNumber;
  final int? age;

  /// Path relative to the API, e.g. `/storage/avatars/...`.
  final String? avatarUrl;
  final String nativeLanguage;
  final UserPlan plan;
  final bool emailVerified;
  final bool phoneVerified;

  /// The account is confirmed once its email or its phone is verified.
  final bool verified;
  final bool hasPassword;

  /// Linked sign in providers, e.g. `google`, `apple`.
  final List<String> providers;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phoneCountry,
    this.phoneNumber,
    this.age,
    this.avatarUrl,
    this.nativeLanguage = 'en',
    this.plan = UserPlan.free,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.verified = false,
    this.hasPassword = true,
    this.providers = const [],
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneCountry: json['phone_country'] as String?,
      phoneNumber: json['phone_number'] as String?,
      age: json['age'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      nativeLanguage: json['native_language'] as String? ?? 'en',
      plan: UserPlan.fromJson(json['plan'] as String?),
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      // Profiles from older API versions have no flag and were verified.
      verified: json['verified'] as bool? ?? true,
      hasPassword: json['has_password'] as bool? ?? true,
      providers:
          (json['providers'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get hasPhone => phoneNumber != null && phoneNumber!.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneCountry,
    phoneNumber,
    age,
    avatarUrl,
    nativeLanguage,
    plan,
    emailVerified,
    phoneVerified,
    verified,
    hasPassword,
    providers,
    createdAt,
  ];
}
