import 'package:vocabo_api/src/auth/token_storage.dart';
import 'package:vocabo_api/src/client/api_client.dart';
import 'package:vocabo_api/src/data_sources/auth_data_source.dart';
import 'package:vocabo_api/src/data_sources/user_data_source.dart';
import 'package:vocabo_api/src/data_sources/user_vocabulary_data_source.dart';
import 'package:vocabo_api/src/data_sources/vocabulary_data_source.dart';
import 'package:vocabo_api/src/repositories/auth_repository.dart';
import 'package:vocabo_api/src/repositories/user_repository.dart';
import 'package:vocabo_api/src/repositories/user_vocabulary_repository.dart';
import 'package:vocabo_api/src/repositories/vocabulary_repository.dart';

class VocaboApiClient {
  final AuthRepository auth;
  final UserRepository user;
  final VocabularyRepository vocabulary;
  final UserVocabularyRepository userVocabulary;

  VocaboApiClient._({
    required this.auth,
    required this.user,
    required this.vocabulary,
    required this.userVocabulary,
  });

  factory VocaboApiClient({
    required String baseUrl,
    required TokenStorage tokenStorage,
  }) {
    final apiClient = ApiClient(
      baseUrl: baseUrl,
      tokenStorage: tokenStorage,
    );
    final dio = apiClient.dio;

    final authDataSource = AuthDataSource(dio);
    final userDataSource = UserDataSource(dio);
    final vocabularyDataSource = VocabularyDataSource(dio);
    final userVocabularyDataSource = UserVocabularyDataSource(dio);

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
    );
  }
}
