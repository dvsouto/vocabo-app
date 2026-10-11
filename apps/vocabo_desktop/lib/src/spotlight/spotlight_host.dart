import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Native side of the spotlight panel.
abstract interface class SpotlightHost {
  Future<void> hide();
  Future<void> setHeight(double height);
  Future<void> openWord({String? userVocabularyId, required String term});

  /// Lets the main window refresh its library after a save.
  Future<void> notifyVocabularyChanged();
}

class MethodChannelSpotlightHost implements SpotlightHost {
  static const _channel = MethodChannel('vocabo/spotlight_actions');

  @override
  Future<void> hide() => _channel.invokeMethod('hide');

  @override
  Future<void> setHeight(double height) =>
      _channel.invokeMethod('setHeight', {'height': height});

  @override
  Future<void> openWord({String? userVocabularyId, required String term}) =>
      _channel.invokeMethod('openWord', {
        'user_vocabulary_id': userVocabularyId,
        'term': term,
      });

  @override
  Future<void> notifyVocabularyChanged() =>
      _channel.invokeMethod('vocabularyChanged');
}

final spotlightHostProvider = Provider<SpotlightHost>(
  (ref) => MethodChannelSpotlightHost(),
);
