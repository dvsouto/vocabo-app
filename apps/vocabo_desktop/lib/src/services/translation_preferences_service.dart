import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class TranslationPreferencesService {
  static const _fileName = 'translation_preferences.json';

  Future<void> save({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      final file = await _getCacheFile();
      final json = jsonEncode({
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      });
      await file.writeAsString(json);
      _log('Saved preferences: $sourceLanguage → $targetLanguage');
    } catch (e) {
      _log('Failed to save preferences: $e');
    }
  }

  Future<({String sourceLanguage, String targetLanguage})?> load() async {
    try {
      final file = await _getCacheFile();
      if (!file.existsSync()) {
        _log('No preferences file found');
        return null;
      }

      final jsonStr = await file.readAsString();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = (
        sourceLanguage: map['source_language'] as String,
        targetLanguage: map['target_language'] as String,
      );
      _log('Loaded preferences: ${result.sourceLanguage} → ${result.targetLanguage}');
      return result;
    } catch (e) {
      _log('Failed to load preferences: $e');
      return null;
    }
  }

  Future<File> _getCacheFile() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/vocabo');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}/$_fileName');
  }

  void _log(String message) {
    dev.log(message, name: 'TranslationPreferencesService');
  }
}
