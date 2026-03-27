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

  AudioPlayerService({
    required VocabularyAudioRepository audioRepository,
    required AudioCacheService cacheService,
  })  : _audioRepository = audioRepository,
        _cacheService = cacheService {
    _player.playerStateStream.listen(_onPlayerStateChanged);
  }

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
    if (_state.status == AudioPlayerStatus.loading ||
        _state.status == AudioPlayerStatus.playing) {
      await stop();
    }

    _failResetTimer?.cancel();

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
        final bytes = await _audioRepository
            .getAudio(vocabularyId: vocabularyId, type: type)
            .timeout(const Duration(seconds: 15));

        final file = await _cacheService.cacheAudio(contentHash, bytes);
        audioPath = file.path;
      }

      if (_state.currentPlayingHash != contentHash) return;

      await _player.stop();
      await _player.setFilePath(audioPath);
      await _player.seek(Duration.zero);
      await _player.play();

      _updateState(_state.copyWith(status: AudioPlayerStatus.playing));
    } catch (e) {
      debugPrint('[AudioPlayer] play() error: $e');
      _updateState(_state.copyWith(status: AudioPlayerStatus.failed));
      _failResetTimer = Timer(const Duration(seconds: 2), () {
        _updateState(const AudioPlayerState());
      });
    }
  }

  Future<void> stop() async {
    _failResetTimer?.cancel();
    await _player.stop();
    _updateState(const AudioPlayerState());
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    if (playerState.processingState == ProcessingState.completed) {
      _updateState(const AudioPlayerState());
    }
  }

  @override
  void dispose() {
    _failResetTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
