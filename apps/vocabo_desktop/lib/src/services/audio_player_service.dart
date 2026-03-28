import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_desktop/src/services/audio_cache_service.dart';

enum AudioPlayerStatus { idle, loading, playing, failed }

class AudioPlayerState {
  final AudioPlayerStatus status;
  final String? currentPlayingHash;

  const AudioPlayerState({
    this.status = AudioPlayerStatus.idle,
    this.currentPlayingHash,
  });

  AudioPlayerState copyWith({
    AudioPlayerStatus? status,
    String? Function()? currentPlayingHash,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      currentPlayingHash: currentPlayingHash != null
          ? currentPlayingHash()
          : this.currentPlayingHash,
    );
  }
}

class AudioPlayerService extends ChangeNotifier {
  final VocabularyAudioRepository _audioRepository;
  final AudioCacheService _cacheService;
  final AudioPlayer _player = AudioPlayer();

  AudioPlayerState _state = const AudioPlayerState();
  Timer? _failResetTimer;
  int _playGeneration = 0;

  AudioPlayerService({
    required VocabularyAudioRepository audioRepository,
    required AudioCacheService cacheService,
  })  : _audioRepository = audioRepository,
        _cacheService = cacheService;

  AudioPlayerState get state => _state;

  void _updateState(AudioPlayerState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> play({
    required String vocabularyId,
    required String type,
    required String contentHash,
  }) async {
    _failResetTimer?.cancel();
    _playGeneration++;
    final generation = _playGeneration;

    await _player.stop();

    _updateState(AudioPlayerState(
      status: AudioPlayerStatus.loading,
      currentPlayingHash: contentHash,
    ));

    try {
      final cached = await _cacheService.getCached(contentHash);
      String audioPath;

      if (cached != null) {
        audioPath = cached.path;
      } else {
        final response = await _audioRepository
            .getAudio(vocabularyId: vocabularyId, type: type)
            .timeout(const Duration(seconds: 15));

        final file = await _cacheService.cacheAudio(
          contentHash,
          response.bytes,
          contentType: response.contentType,
        );
        audioPath = file.path;
      }

      if (generation != _playGeneration) return;

      await _player.setFilePath(audioPath);

      if (generation != _playGeneration) return;

      _updateState(_state.copyWith(status: AudioPlayerStatus.playing));

      await _player.play();

      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 30));

      if (generation == _playGeneration) {
        _updateState(const AudioPlayerState());
      }
    } catch (e) {
      appLogger.error('AudioPlayer play() error', e);
      if (generation != _playGeneration) return;

      _updateState(_state.copyWith(status: AudioPlayerStatus.failed));
      _failResetTimer = Timer(const Duration(seconds: 2), () {
        if (_playGeneration == generation) {
          _updateState(const AudioPlayerState());
        }
      });
    }
  }

  Future<void> stop() async {
    _failResetTimer?.cancel();
    _playGeneration++;
    await _player.stop();
    _updateState(const AudioPlayerState());
  }

  @override
  void dispose() {
    _failResetTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
