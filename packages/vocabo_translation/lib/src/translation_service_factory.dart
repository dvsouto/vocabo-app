import 'dart:io' show Platform;

import 'apple_translation_service.dart';
import 'fallback_translation_service.dart';
import 'translation_service.dart';

class TranslationServiceFactory {
  /// The on-device translator of this platform. Apple's framework serves
  /// macOS and iOS 26+; [fallback] (ML Kit, provided by the mobile app)
  /// covers Android and older iPhones.
  static TranslationService create({TranslationService? fallback}) {
    if (Platform.isMacOS) return AppleTranslationService();
    if (Platform.isIOS) {
      final apple = AppleTranslationService();
      return fallback == null
          ? apple
          : FallbackTranslationService(primary: apple, fallback: fallback);
    }
    if (Platform.isAndroid && fallback != null) return fallback;
    throw UnsupportedError(
      'Translation is not supported on ${Platform.operatingSystem}',
    );
  }
}
