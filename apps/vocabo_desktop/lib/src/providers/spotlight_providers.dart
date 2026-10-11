import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vocabo_core/vocabo_core.dart';

/// The hotkey is a per-device choice, so it is stored locally rather than in
/// the synced user preferences.
class SpotlightPreferencesService {
  static const _fileName = 'spotlight_preferences.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final folder = Directory('${dir.path}/vocabo');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    return File('${folder.path}/$_fileName');
  }

  Future<bool> loadEnabled() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return true;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return json['enabled'] as bool? ?? true;
    } catch (e, st) {
      appLogger.handle(e, st, 'SpotlightPreferences loadEnabled() error');
      return true;
    }
  }

  Future<void> saveEnabled(bool enabled) async {
    final file = await _file();
    await file.writeAsString(jsonEncode({'enabled': enabled}));
  }
}

final spotlightPreferencesServiceProvider =
    Provider<SpotlightPreferencesService>(
      (ref) => SpotlightPreferencesService(),
    );

class SpotlightEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() =>
      ref.watch(spotlightPreferencesServiceProvider).loadEnabled();

  Future<void> setEnabled(bool enabled) async {
    state = AsyncData(enabled);
    await ref.read(spotlightPreferencesServiceProvider).saveEnabled(enabled);
  }
}

final spotlightEnabledProvider =
    AsyncNotifierProvider<SpotlightEnabledNotifier, bool>(
      SpotlightEnabledNotifier.new,
    );
