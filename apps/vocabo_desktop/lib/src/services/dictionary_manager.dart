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
    DateTime? cachedDate;
    if (versionFile.existsSync()) {
      cachedVersion = versionFile.readAsStringSync().trim();
      cachedDate = versionFile.lastModifiedSync();
    }

    appLogger.info('Initializing dictionary for lang=$lang');
    appLogger.info('Cached version: ${cachedVersion ?? "none"}');
    if (cachedDate != null) {
      appLogger.info('Last downloaded: $cachedDate');
    }

    // Check remote version
    String? remoteVersion;
    try {
      final versionInfo = await _repository.getVersion(lang: lang);
      remoteVersion = versionInfo.version;
      appLogger.info('Remote version: $remoteVersion (${versionInfo.wordCount} words)');
    } catch (e) {
      appLogger.info('API unreachable, falling back to cache: $e');
    }

    List<DictionaryWord> words;

    if (dataFile.existsSync() &&
        (remoteVersion == null || remoteVersion == cachedVersion)) {
      appLogger.info('Loading from cache (version matches or API unavailable)');
      words = await _loadFromCache(dataFile);
      appLogger.info('Loaded ${words.length} words from cache');
    } else {
      // Download fresh data
      try {
        appLogger.info('Starting download for lang=$lang...');
        final stopwatch = Stopwatch()..start();

        words = await _repository.download(lang: lang);

        stopwatch.stop();
        appLogger.info('Download completed: ${words.length} words in ${stopwatch.elapsedMilliseconds}ms');

        await _saveToCache(dataFile, words);
        if (remoteVersion != null) {
          versionFile.writeAsStringSync(remoteVersion);
          appLogger.info('Saved version: $remoteVersion');
        }
      } catch (e) {
        appLogger.info('Download failed: $e');
        if (dataFile.existsSync()) {
          appLogger.info('Falling back to cache');
          words = await _loadFromCache(dataFile);
          appLogger.info('Loaded ${words.length} words from cache');
        } else {
          appLogger.info('No cache available, dictionary not loaded');
          return;
        }
      }
    }

    _searchEngine = FuzzySearchEngine();
    _searchEngine!.load(words);
    appLogger.info('Search engine ready with ${words.length} words');
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
