import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/providers/user_profile_provider.dart';

/// Keeps the interface language on disk so the sign-in screens, the menu
/// bar panel and the spotlight (separate engines) use it before the profile
/// loads.
class InterfaceLanguageStore {
  static const _fileName = 'interface_language.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/vocabo');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return File('${folder.path}/$_fileName');
  }

  Future<String?> read() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return json['interface_language'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String code) async {
    try {
      final file = await _file();
      await file.writeAsString(jsonEncode({'interface_language': code}));
    } catch (e, st) {
      appLogger.handle(e, st, 'InterfaceLanguageStore write() error');
    }
  }
}

final interfaceLanguageStoreProvider = Provider<InterfaceLanguageStore>(
  (_) => InterfaceLanguageStore(),
);

/// The system's preferred interface language, or English.
String systemInterfaceLanguage() => suggestInterfaceLanguage([
  for (final locale in PlatformDispatcher.instance.locales) locale.languageCode,
]);

/// Language code of the app interface. The signed-in profile is the source
/// of truth; the local copy covers the time before it loads.
class InterfaceLanguageNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final store = ref.watch(interfaceLanguageStoreProvider);

    ref.listen(userProfileProvider, (_, next) {
      final fromProfile = next.valueOrNull?.interfaceLanguage;
      if (fromProfile != null && fromProfile != state.valueOrNull) {
        state = AsyncData(fromProfile);
        store.write(fromProfile);
      }
    });

    return await store.read() ?? systemInterfaceLanguage();
  }

  /// Applies the language right away and saves it locally and, when signed
  /// in, on the profile.
  Future<void> select(String code, {bool signedIn = true}) async {
    state = AsyncData(code);
    await ref.read(interfaceLanguageStoreProvider).write(code);
    if (!signedIn) return;

    try {
      await ref
          .read(apiClientProvider)
          .user
          .updateProfile(interfaceLanguage: code);
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Interface language sync failed');
    }
  }
}

final interfaceLanguageProvider =
    AsyncNotifierProvider<InterfaceLanguageNotifier, String>(
      InterfaceLanguageNotifier.new,
    );

Locale _supported(String code) {
  final locale = Locale(code);
  return AppLocalizations.supportedLocales.contains(locale)
      ? locale
      : const Locale('en');
}

final appLocaleProvider = Provider<Locale>((ref) {
  final code =
      ref.watch(interfaceLanguageProvider).valueOrNull ??
      systemInterfaceLanguage();
  return _supported(code);
});

/// Translations for code without a [BuildContext], such as providers and
/// notifications.
final appLocalizationsProvider = Provider<AppLocalizations>(
  (ref) => lookupAppLocalizations(ref.watch(appLocaleProvider)),
);
