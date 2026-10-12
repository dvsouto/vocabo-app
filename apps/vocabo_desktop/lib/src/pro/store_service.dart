import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vocabo_api/vocabo_api.dart';

/// Store identifiers of the Pro subscription, same in App Store Connect
/// and Google Play Console. The 3-day free trial is an introductory offer
/// configured in both stores.
const proMonthlyProductId = 'vocabo_pro_monthly';
const proYearlyProductId = 'vocabo_pro_yearly';
const proProductIds = {proMonthlyProductId, proYearlyProductId};

enum StorePurchaseEvent { pending, completed, canceled, failed }

/// Buys and restores the Pro subscription and confirms every purchase with
/// the API, which decides the plan.
class StoreService {
  StoreService({required this.api, InAppPurchase? store, this.onEvent})
    : _store = store ?? InAppPurchase.instance {
    _subscription = _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object e, StackTrace st) {
        appLogger.handle(e, st, 'Store purchaseStream error');
        onEvent?.call(StorePurchaseEvent.failed);
      },
    );
  }

  final VocaboApiClient api;
  final void Function(StorePurchaseEvent event)? onEvent;
  final InAppPurchase _store;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;

  void dispose() => _subscription.cancel();

  Future<bool> isAvailable() => _store.isAvailable();

  /// Pro products with the store's localized prices, monthly first.
  Future<List<ProductDetails>> loadProducts() async {
    if (!await isAvailable()) return const [];
    final response = await _store.queryProductDetails(proProductIds);
    if (response.error != null) {
      appLogger.warning('Store products error: ${response.error}');
    }
    return [...response.productDetails]..sort(
      (a, b) => a.id == proMonthlyProductId ? -1 : (b.id == a.id ? 0 : 1),
    );
  }

  /// [userId] travels with the purchase (appAccountToken on the App Store,
  /// obfuscated account id on Google Play) so store notifications reach the
  /// right account.
  Future<void> buy(ProductDetails product, {required String userId}) async {
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      ),
    );
  }

  Future<void> restore({required String userId}) =>
      _store.restorePurchases(applicationUserName: userId);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          onEvent?.call(StorePurchaseEvent.pending);
        case PurchaseStatus.canceled:
          onEvent?.call(StorePurchaseEvent.canceled);
        case PurchaseStatus.error:
          appLogger.warning('Store purchase error: ${purchase.error}');
          onEvent?.call(StorePurchaseEvent.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _confirm(purchase);
      }

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
  }

  Future<void> _confirm(PurchaseDetails purchase) async {
    if (!proProductIds.contains(purchase.productID)) return;
    final proof = purchase.verificationData.serverVerificationData;
    try {
      if (Platform.isAndroid) {
        await api.subscriptions.confirmGooglePlay(proof);
      } else {
        await api.subscriptions.confirmAppStore(proof);
      }
      onEvent?.call(StorePurchaseEvent.completed);
    } catch (e, st) {
      appLogger.handle(e, st, 'Store purchase confirmation failed');
      onEvent?.call(StorePurchaseEvent.failed);
    }
  }
}
