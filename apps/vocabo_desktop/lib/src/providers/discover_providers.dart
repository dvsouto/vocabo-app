import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_desktop/src/providers/api_client_provider.dart';

enum LibraryTab { myWords, forYou, collections }

/// Active Library tab, so other screens can open a given tab.
final libraryTabProvider = StateProvider<LibraryTab>((_) => LibraryTab.myWords);

/// The collection opened in the Collections tab, or null for the catalog.
final openCollectionIdProvider = StateProvider<String?>((_) => null);

final collectionsProvider = FutureProvider<List<WordCollection>>((ref) {
  return ref.watch(apiClientProvider).discover.getCollections();
});

final collectionDetailProvider = FutureProvider.autoDispose
    .family<CollectionDetail, String>((ref, id) {
      return ref.watch(apiClientProvider).discover.getCollection(id);
    });

/// Today's recommendations; made by the API on the first visit of the day.
final recommendationsProvider = FutureProvider<Recommendations>((ref) {
  return ref
      .watch(apiClientProvider)
      .discover
      .getRecommendations(
        timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
      );
});

/// Translations fetched on demand for suggested and collection words,
/// cached for the session.
final suggestedVocabularyProvider = FutureProvider.family<Vocabulary, String>((
  ref,
  term,
) {
  return ref.watch(apiClientProvider).discover.translate(term);
});
