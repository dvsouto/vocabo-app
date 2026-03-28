import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocabo_core/vocabo_core.dart';

class UserVocabularyCacheService {
  static const _fileName = 'user_vocabulary_cache.json';

  Future<void> save(List<UserVocabulary> items) async {
    try {
      final file = await _getCacheFile();
      final jsonStr = jsonEncode(items.map((uv) => uv.toJson()).toList());
      await file.writeAsString(jsonStr);
      _log('Saved ${items.length} items to cache');
    } catch (e) {
      _log('Failed to save cache: $e');
    }
  }

  Future<List<UserVocabulary>?> load() async {
    try {
      final file = await _getCacheFile();
      if (!file.existsSync()) {
        _log('No cache file found');
        return null;
      }

      final jsonStr = await file.readAsString();
      final list = jsonDecode(jsonStr) as List<dynamic>;
      final items = list
          .map((item) =>
              UserVocabulary.fromJson(item as Map<String, dynamic>))
          .toList();
      _log('Loaded ${items.length} items from cache');
      return items;
    } catch (e) {
      _log('Failed to load cache: $e');
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
    dev.log(message, name: 'UserVocabularyCacheService');
  }
}
