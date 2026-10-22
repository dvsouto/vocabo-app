import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vocabo_api/vocabo_api.dart';

import 'package:vocabo_app/src/services/audio_cache_service.dart';

enum AudioPlayerStatus { idle, loading, playing, failed }

/// The speed of a slow replay, for learners to catch each sound.
const slowAudioSpeed = 0.5;

/// How long after a word finishes a second click still means "slower".
const _replaySlowWindow = Duration(seconds: 8);

class AudioPlayerState {
  final AudioPlayerStatus status;
  final String? currentPlayingHash;
  final double speed;

  const AudioPlayerState({
    this.status = AudioPlayerStatus.idle,
    this.currentPlayingHash,
    this.speed = 1,
  });

  bool get isSlow => speed < 1;

  AudioPlayerState copyWith({
    AudioPlayerStatus? status,
    String? Function()? currentPlayingHash,
  }) {
    return AudioPlayerState(
      status: status ?? this.status,
      currentPlayingHash: currentPlayingHash != null
          ? currentPlayingHash()
          : this.currentPlayingHash,
      speed: speed,
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
  String? _lastFinishedHash;
  DateTime? _lastFinishedAt;
  double _lastFinishedSpeed = 1;

  AudioPlayerService({
    required VocabularyAudioRepository audioRepository,
    required AudioCacheService cacheService,
    required String Function() voice,
  }) : _audioRepository = audioRepository,
       _cacheService = cacheService,
       _voice = voice;

  /// The user's preferred voice gender, read on every play.
  final String Function() _voice;

  AudioPlayerState get state => _state;

  void _updateState(AudioPlayerState newState) {
    _state = newState;
    notifyListeners();
  }

  /// What a click on a play button does, like Google Translate: the clicks
  /// on the same word alternate between normal speed and [slowAudioSpeed],
  /// whether the previous play is still running or just ended. Another word,
  /// or a pause longer than [_replaySlowWindow], starts over at normal speed.
  Future<void> toggle({
    required String vocabularyId,
    required String type,
    required String contentHash,
  }) {
    final isThis = _state.currentPlayingHash == contentHash;
    final active =
        isThis &&
        (_state.status == AudioPlayerStatus.loading ||
            _state.status == AudioPlayerStatus.playing);

    final finishedAt = _lastFinishedAt;
    final justHeardNormal =
        _lastFinishedHash == contentHash &&
        _lastFinishedSpeed == 1 &&
        finishedAt != null &&
        DateTime.now().difference(finishedAt) < _replaySlowWindow;

    final slowNext = active ? !_state.isSlow : justHeardNormal;
    return play(
      vocabularyId: vocabularyId,
      type: type,
      contentHash: contentHash,
      speed: slowNext ? slowAudioSpeed : 1,
    );
  }

  Future<void> play({
    required String vocabularyId,
    required String type,
    required String contentHash,
    double speed = 1,
  }) async {
    _failResetTimer?.cancel();
    _playGeneration++;
    final generation = _playGeneration;
    _lastFinishedHash = null;

    await _player.stop();

    _updateState(
      AudioPlayerState(
        status: AudioPlayerStatus.loading,
        currentPlayingHash: contentHash,
        speed: speed,
      ),
    );

    try {
      final voice = _voice();
      final cached = await _cacheService.getCached(contentHash, voice: voice);
      String audioPath;

      if (cached != null) {
        audioPath = cached.path;
      } else {
        final response = await _audioRepository
            .getAudio(vocabularyId: vocabularyId, type: type, voice: voice)
            .timeout(const Duration(seconds: 15));

        final file = await _cacheService.cacheAudio(
          contentHash,
          response.bytes,
          voice: voice,
          contentType: response.contentType,
        );
        audioPath = file.path;
      }

      if (generation != _playGeneration) return;

      await _player.setFilePath(audioPath);
      await _player.setSpeed(speed);

      if (generation != _playGeneration) return;

      _updateState(_state.copyWith(status: AudioPlayerStatus.playing));

      await _player.play();

      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 30));

      if (generation == _playGeneration) {
        _lastFinishedHash = contentHash;
        _lastFinishedAt = DateTime.now();
        _lastFinishedSpeed = speed;
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
