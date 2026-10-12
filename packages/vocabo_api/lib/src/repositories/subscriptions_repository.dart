import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_api/src/client/api_call.dart';
import 'package:vocabo_api/src/data_sources/subscriptions_data_source.dart';

class SubscriptionsRepository {
  final SubscriptionsDataSource _dataSource;

  SubscriptionsRepository({required SubscriptionsDataSource dataSource})
    : _dataSource = dataSource;

  /// Plan, limits, today's usage and the store subscription.
  Future<PlanStatus> getStatus() => apiCall(_dataSource.getStatus);

  /// Sends a StoreKit 2 signed transaction after a purchase or a restore.
  Future<PlanStatus> confirmAppStore(String signedTransaction) =>
      apiCall(() => _dataSource.confirmAppStore(signedTransaction));

  /// Sends a Google Play purchase token after a purchase or a restore.
  Future<PlanStatus> confirmGooglePlay(String purchaseToken) =>
      apiCall(() => _dataSource.confirmGooglePlay(purchaseToken));
}
