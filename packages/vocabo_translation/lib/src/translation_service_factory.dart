import 'dart:io' show Platform;

import 'apple_translation_service.dart';
import 'mlkit_translation_service.dart';
import 'translation_service.dart';

class TranslationServiceFactory {
  static TranslationService create() {
    if (Platform.isMacOS || Platform.isIOS) {
      return AppleTranslationService();
    }
    if (Platform.isAndroid) {
      return MlKitTranslationService();
    }
    throw UnsupportedError(
      'Translation is not supported on ${Platform.operatingSystem}',
    );
  }
}
