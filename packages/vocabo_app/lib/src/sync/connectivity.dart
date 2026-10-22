import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

/// Whether the app can reach the API. The network interface tells when the
/// device went offline; requests tell when the API itself is unreachable.
class ConnectivityNotifier extends Notifier<bool> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  bool build() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (state != hasNetwork) state = hasNetwork;
    }, onError: (Object e, StackTrace st) => appLogger.handle(e, st));
    ref.onDispose(() => _subscription?.cancel());
    Connectivity().checkConnectivity().then((results) {
      state = results.any((r) => r != ConnectivityResult.none);
    }, onError: (_) {});
    return true;
  }

  /// A request reached the API.
  void reportOnline() {
    if (!state) state = true;
  }

  /// A request failed for lack of connection.
  void reportOffline() {
    if (state) state = false;
  }
}

final isOnlineProvider = NotifierProvider<ConnectivityNotifier, bool>(
  ConnectivityNotifier.new,
);

/// Thrown by cached reads that have nothing local and no connection, so the
/// screen can show the offline notice instead of an error.
class OfflineUnavailableException implements Exception {
  const OfflineUnavailableException();
}

bool isConnectionError(Object error) => error is NetworkException;

/// Errors that only mean "not available offline".
bool isOfflineError(Object error) =>
    error is NetworkException || error is OfflineUnavailableException;
