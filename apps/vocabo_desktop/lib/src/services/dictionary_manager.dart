import 'dart:convert';
import 'dart:developer' as dev;
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

    _log('Initializing dictionary for lang=$lang');
    _log('Cached version: ${cachedVersion ?? "none"}');
    if (cachedDate != null) {
      _log('Last downloaded: $cachedDate');
    }

    // Check remote version
    String? remoteVersion;
    try {
      final versionInfo = await _repository.getVersion(lang: lang);
      remoteVersion = versionInfo.version;
      _log('Remote version: $remoteVersion (${versionInfo.wordCount} words)');
    } catch (e) {
      _log('API unreachable, falling back to cache: $e');
    }

    List<DictionaryWord> words;

    if (dataFile.existsSync() &&
        (remoteVersion == null || remoteVersion == cachedVersion)) {
      _log('Loading from cache (version matches or API unavailable)');
      words = await _loadFromCache(dataFile);
      _log('Loaded ${words.length} words from cache');
    } else {
      // Download fresh data
      try {
        _log('Starting download for lang=$lang...');
        final stopwatch = Stopwatch()..start();

        words = await _repository.download(lang: lang);

        stopwatch.stop();
        _log('Download completed: ${words.length} words in ${stopwatch.elapsedMilliseconds}ms');

        await _saveToCache(dataFile, words);
        if (remoteVersion != null) {
          versionFile.writeAsStringSync(remoteVersion);
          _log('Saved version: $remoteVersion');
        }
      } catch (e) {
        _log('Download failed: $e');
        if (dataFile.existsSync()) {
          _log('Falling back to cache');
          words = await _loadFromCache(dataFile);
          _log('Loaded ${words.length} words from cache');
        } else {
          _log('No cache available, dictionary not loaded');
          return;
        }
      }
    }

    _searchEngine = FuzzySearchEngine();
    _searchEngine!.load(words);
    _log('Search engine ready with ${words.length} words');
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

  void _log(String message) {
    dev.log(message, name: 'DictionaryManager');
  }
}
