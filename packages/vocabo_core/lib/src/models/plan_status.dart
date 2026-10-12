import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/models/user.dart';

/// What the current plan allows. Null numeric limits mean unlimited.
class PlanLimits extends Equatable {
  final int? libraryWords;
  final int? dailyLookups;
  final int devices;
  final bool fullStats;
  final bool archive;
  final bool reverseCards;
  final bool export;

  const PlanLimits({
    this.libraryWords,
    this.dailyLookups,
    this.devices = 1,
    this.fullStats = false,
    this.archive = false,
    this.reverseCards = false,
    this.export = false,
  });

  factory PlanLimits.fromJson(Map<String, dynamic> json) => PlanLimits(
    libraryWords: json['library_words'] as int?,
    dailyLookups: json['daily_lookups'] as int?,
    devices: json['devices'] as int? ?? 1,
    fullStats: json['full_stats'] as bool? ?? false,
    archive: json['archive'] as bool? ?? false,
    reverseCards: json['reverse_cards'] as bool? ?? false,
    export: json['export'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [
    libraryWords,
    dailyLookups,
    devices,
    fullStats,
    archive,
    reverseCards,
    export,
  ];
}

/// The store subscription behind a Pro plan.
class PlanSubscription extends Equatable {
  final String platform;
  final String productId;
  final bool isTrial;
  final bool autoRenew;
  final DateTime? expiresAt;

  const PlanSubscription({
    required this.platform,
    required this.productId,
    required this.isTrial,
    required this.autoRenew,
    this.expiresAt,
  });

  factory PlanSubscription.fromJson(Map<String, dynamic> json) =>
      PlanSubscription(
        platform: json['platform'] as String,
        productId: json['product_id'] as String,
        isTrial: json['is_trial'] as bool? ?? false,
        autoRenew: json['auto_renew'] as bool? ?? false,
        expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? ''),
      );

  bool get isAppStore => platform == 'app_store';

  @override
  List<Object?> get props => [
    platform,
    productId,
    isTrial,
    autoRenew,
    expiresAt,
  ];
}

class PlanStatus extends Equatable {
  final UserPlan plan;
  final PlanLimits limits;
  final int libraryWords;
  final int dailyLookups;
  final PlanSubscription? subscription;

  const PlanStatus({
    required this.plan,
    required this.limits,
    required this.libraryWords,
    required this.dailyLookups,
    this.subscription,
  });

  factory PlanStatus.fromJson(Map<String, dynamic> json) {
    final usage = json['usage'] as Map<String, dynamic>? ?? const {};
    final subscription = json['subscription'] as Map<String, dynamic>?;
    return PlanStatus(
      plan: UserPlan.fromJson(json['plan'] as String?),
      limits: PlanLimits.fromJson(
        json['limits'] as Map<String, dynamic>? ?? const {},
      ),
      libraryWords: usage['library_words'] as int? ?? 0,
      dailyLookups: usage['daily_lookups'] as int? ?? 0,
      subscription: subscription == null
          ? null
          : PlanSubscription.fromJson(subscription),
    );
  }

  bool get isPro => plan == UserPlan.pro;

  @override
  List<Object?> get props => [
    plan,
    limits,
    libraryWords,
    dailyLookups,
    subscription,
  ];
}
