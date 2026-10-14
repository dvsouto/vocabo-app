import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/pro/store_service.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/providers/user_profile_provider.dart';

/// Plan, limits and usage of the signed-in account.
final planStatusProvider = FutureProvider<PlanStatus>((ref) {
  return ref.watch(apiClientProvider).subscriptions.getStatus();
});

enum UpgradeTrigger { manual, libraryFull, dailyLookups, feature }

/// Why the paywall opens, so it can lead with the relevant benefit.
class UpgradeReason {
  const UpgradeReason(this.trigger, {this.max});

  const UpgradeReason.manual() : this(UpgradeTrigger.manual);

  final UpgradeTrigger trigger;
  final int? max;

  String headline(AppLocalizations l10n) => switch (trigger) {
    UpgradeTrigger.libraryFull => l10n.proLimitLibrary(max ?? 0),
    UpgradeTrigger.dailyLookups => l10n.proLimitDailyLookups(max ?? 0),
    UpgradeTrigger.feature => l10n.proFeatureLocked,
    UpgradeTrigger.manual => l10n.proPaywallTitle,
  };
}

/// The upgrade reason when [error] is a plan limit or a Pro-only feature.
UpgradeReason? upgradeReasonFor(Object error) {
  if (error is! ForbiddenException) return null;
  final max = int.tryParse(error.details['max']?.firstOrNull ?? '');
  return switch (error.code) {
    'plan_limit' => UpgradeReason(
      error.details['limit']?.firstOrNull == 'daily_lookups'
          ? UpgradeTrigger.dailyLookups
          : UpgradeTrigger.libraryFull,
      max: max,
    ),
    'pro_required' => const UpgradeReason(UpgradeTrigger.feature),
    _ => null,
  };
}

/// Set to open the paywall from anywhere in the main window.
final upgradePromptProvider = StateProvider<UpgradeReason?>((_) => null);

/// Last purchase event, shown by the paywall.
final storeEventProvider = StateProvider<StorePurchaseEvent?>((_) => null);

final storeServiceProvider = Provider<StoreService>((ref) {
  final service = StoreService(
    api: ref.watch(apiClientProvider),
    onEvent: (event) {
      ref.read(storeEventProvider.notifier).state = event;
      if (event == StorePurchaseEvent.completed) {
        ref.invalidate(planStatusProvider);
        ref.invalidate(userProfileProvider);
      }
    },
  );
  ref.onDispose(service.dispose);
  return service;
});

final storeProductsProvider = FutureProvider<List<ProductDetails>>(
  (ref) => ref.watch(storeServiceProvider).loadProducts(),
);
