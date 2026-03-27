import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  String? _cacheDirPath;

  Future<String> get _cacheDir async {
    if (_cacheDirPath != null) return _cacheDirPath!;
    final dir = await getApplicationCacheDirectory();
    _cacheDirPath = '${dir.path}/audio';
    await Directory(_cacheDirPath!).create(recursive: true);
    return _cacheDirPath!;
  }

  Future<File?> getCached(String contentHash) async {
    final path = await _getAudioPath(contentHash);
    final file = File(path);
    if (await file.exists()) return file;
    return null;
  }

  Future<File> cacheAudio(String contentHash, Uint8List bytes) async {
    final path = await _getAudioPath(contentHash);
    final file = File(path);
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<String> _getAudioPath(String contentHash) async {
    final dir = await _cacheDir;
    return '$dir/$contentHash.mp3';
  }
}
