import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:vocabo_api/vocabo_api.dart';

class DictionaryManager {
  final DictionaryRepository _repository;
  FuzzySearchEngine? _searchEngine;

  DictionaryManager({required DictionaryRepository repository})
      : _repository = repository;

  FuzzySearchEngine? get searchEngine => _searchEngine;
  bool get isLoaded => _searchEngine?.isLoaded ?? false;

  Future<void> initialize(String lang) async {
    final cacheDir = await _getCacheDirectory();
    final dataFile = File('${cacheDir.path}/$lang.json.gz');
    final versionFile = File('${cacheDir.path}/$lang.version');

    String? cachedVersion;
    if (versionFile.existsSync()) {
      cachedVersion = versionFile.readAsStringSync().trim();
    }

    // Check remote version
    String? remoteVersion;
    try {
      final versionInfo = await _repository.getVersion(lang: lang);
      remoteVersion = versionInfo.version;
    } catch (_) {
      // If API is unreachable, fall back to cache
    }

    List<DictionaryWord> words;

    if (dataFile.existsSync() &&
        (remoteVersion == null || remoteVersion == cachedVersion)) {
      // Load from cache
      words = await _loadFromCache(dataFile);
    } else {
      // Download fresh data
      try {
        words = await _repository.download(lang: lang);
        await _saveToCache(dataFile, words);
        if (remoteVersion != null) {
          versionFile.writeAsStringSync(remoteVersion);
        }
      } catch (_) {
        // If download fails and cache exists, use cache
        if (dataFile.existsSync()) {
          words = await _loadFromCache(dataFile);
        } else {
          return;
        }
      }
    }

    _searchEngine = FuzzySearchEngine();
    _searchEngine!.load(words);
  }

  Future<Directory> _getCacheDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory('${appSupport.path}/dictionaries');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<List<DictionaryWord>> _loadFromCache(File file) async {
    final bytes = file.readAsBytesSync();
    final decompressed = gzip.decode(bytes);
    final jsonStr = utf8.decode(decompressed);
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((item) =>
            DictionaryWord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveToCache(File file, List<DictionaryWord> words) async {
    final jsonStr = jsonEncode(words.map((w) => w.toJson()).toList());
    final compressed = gzip.encode(utf8.encode(jsonStr));
    file.writeAsBytesSync(compressed);
  }
}
