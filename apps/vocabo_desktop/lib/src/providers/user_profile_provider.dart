import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';

final userProfileProvider = FutureProvider<User>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.user.getProfile();
});
