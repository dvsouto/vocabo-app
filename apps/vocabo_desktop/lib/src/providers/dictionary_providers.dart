import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/services/dictionary_manager.dart';

final dictionaryManagerProvider = Provider<DictionaryManager>((ref) {
  final api = ref.watch(apiClientProvider);
  return DictionaryManager(repository: api.dictionary);
});

final dictionaryInitProvider = FutureProvider<void>((ref) async {
  final manager = ref.watch(dictionaryManagerProvider);
  await manager.initialize('en');
});
