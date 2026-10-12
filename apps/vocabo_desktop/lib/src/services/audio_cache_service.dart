import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  String? _cacheDirPath;

  Future<void> init() async {
    final dir = await getApplicationCacheDirectory();
    _cacheDirPath = '${dir.path}/audio';
    await Directory(_cacheDirPath!).create(recursive: true);
  }

  /// Files cached before voices were selectable hold the female voice.
  List<String> _names(String contentHash, String voice) => [
    '$contentHash-$voice',
    if (voice == 'female') contentHash,
  ];

  Future<File?> getCached(String contentHash, {required String voice}) async {
    if (_cacheDirPath == null) await init();
    for (final name in _names(contentHash, voice)) {
      for (final ext in ['ogg', 'mp3']) {
        final file = File('$_cacheDirPath/$name.$ext');
        if (await file.exists()) return file;
      }
    }
    return null;
  }

  Future<File> cacheAudio(
    String contentHash,
    Uint8List bytes, {
    required String voice,
    String? contentType,
  }) async {
    if (_cacheDirPath == null) await init();
    final ext = _extensionFromContentType(contentType);
    final file = File('$_cacheDirPath/$contentHash-$voice.$ext');
    await file.writeAsBytes(bytes);
    return file;
  }

  String _extensionFromContentType(String? contentType) {
    if (contentType != null && contentType.contains('ogg')) return 'ogg';
    return 'mp3';
  }
}
