import 'package:vocabo_api/src/auth/token_storage.dart';
import 'package:vocabo_api/src/client/api_client.dart';
import 'package:vocabo_api/src/client/device_info.dart';
import 'package:vocabo_api/src/client/interceptors/auth_interceptor.dart';
import 'package:vocabo_api/src/data_sources/auth_data_source.dart';
import 'package:vocabo_api/src/data_sources/dictionary_data_source.dart';
import 'package:vocabo_api/src/data_sources/flashcards_data_source.dart';
import 'package:vocabo_api/src/data_sources/lookups_data_source.dart';
import 'package:vocabo_api/src/data_sources/subscriptions_data_source.dart';
import 'package:vocabo_api/src/data_sources/user_data_source.dart';
import 'package:vocabo_api/src/data_sources/user_vocabulary_data_source.dart';
import 'package:vocabo_api/src/data_sources/vocabulary_audio_data_source.dart';
import 'package:vocabo_api/src/data_sources/vocabulary_data_source.dart';
import 'package:vocabo_api/src/repositories/auth_repository.dart';
import 'package:vocabo_api/src/repositories/dictionary_repository.dart';
import 'package:vocabo_api/src/repositories/flashcards_repository.dart';
import 'package:vocabo_api/src/repositories/lookups_repository.dart';
import 'package:vocabo_api/src/repositories/study_notes_repository.dart';
import 'package:vocabo_api/src/repositories/subscriptions_repository.dart';
import 'package:vocabo_api/src/repositories/user_repository.dart';
import 'package:vocabo_api/src/repositories/user_vocabulary_repository.dart';
import 'package:vocabo_api/src/repositories/vocabulary_audio_repository.dart';
import 'package:vocabo_api/src/repositories/vocabulary_repository.dart';

class VocaboApiClient {
  final AuthRepository auth;
  final UserRepository user;
  final VocabularyRepository vocabulary;
  final UserVocabularyRepository userVocabulary;
  final DictionaryRepository dictionary;
  final VocabularyAudioRepository vocabularyAudio;
  final FlashcardsRepository flashcards;
  final LookupsRepository lookups;
  final SubscriptionsRepository subscriptions;
  final StudyNotesRepository studyNotes;

  VocaboApiClient._({
    required this.auth,
    required this.user,
    required this.vocabulary,
    required this.userVocabulary,
    required this.dictionary,
    required this.vocabularyAudio,
    required this.flashcards,
    required this.lookups,
    required this.subscriptions,
    required this.studyNotes,
  });

  factory VocaboApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
    DeviceInfo device = const DeviceInfo(),
    SessionEndedCallback? onSessionEnded,
  }) {
    final apiClient = ApiClient(
      baseUrl: baseUrl,
      tokenStorage: tokenStorage,
      onSessionEnded: onSessionEnded,
    );
    final dio = apiClient.dio;

    final authDataSource = AuthDataSource(dio, device: device);
    final userDataSource = UserDataSource(dio);
    final vocabularyDataSource = VocabularyDataSource(dio);
    final userVocabularyDataSource = UserVocabularyDataSource(dio);
    final dictionaryDataSource = DictionaryDataSource(dio);
    final vocabularyAudioDataSource = VocabularyAudioDataSource(dio);
    final flashcardsDataSource = FlashcardsDataSource(dio);
    final lookupsDataSource = LookupsDataSource(dio);

    return VocaboApiClient._(
      auth: AuthRepository(
        dataSource: authDataSource,
        tokenStorage: tokenStorage,
      ),
      user: UserRepository(dataSource: userDataSource),
      vocabulary: VocabularyRepository(dataSource: vocabularyDataSource),
      userVocabulary: UserVocabularyRepository(
        dataSource: userVocabularyDataSource,
      ),
      dictionary: DictionaryRepository(dataSource: dictionaryDataSource),
      vocabularyAudio: VocabularyAudioRepository(
        dataSource: vocabularyAudioDataSource,
      ),
      flashcards: FlashcardsRepository(dataSource: flashcardsDataSource),
      lookups: LookupsRepository(dataSource: lookupsDataSource),
      subscriptions: SubscriptionsRepository(
        dataSource: SubscriptionsDataSource(dio),
      ),
      studyNotes: StudyNotesRepository(dio),
    );
  }
}
