import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../models/track.dart';

class WAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<Track> _queue = [];

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  int get currentIndex => _player.currentIndex ?? 0;

  WAudioHandler() {
    _player.setAudioSource(_playlist);
    _listenToPlayerState();
    _listenToCurrentIndex();
    _listenToDuration();
  }

  // เพิ่ม startIndex เข้าไปแล้วครับ
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    _queue.clear();
    _queue.addAll(tracks);

    await _playlist.clear();
    await _playlist.addAll(tracks.map((t) => AudioSource.file(t.filePath)).toList());

    queue.add(_queue.map(_trackToMediaItem).toList());

    // เริ่มเล่นที่ตำแหน่งที่กำหนด
    await _player.seek(Duration.zero, index: startIndex);
    await _player.play();
  }

  Future<void> addTrack(Track track) async {
    _queue.add(track);
    await _playlist.add(AudioSource.file(track.filePath));
    queue.add(_queue.map(_trackToMediaItem).toList());
  }

  /// Adds many tracks in one go (e.g. importing a folder of local songs).
  /// Appends to whatever is already loaded instead of replacing it, and
  /// does NOT start/interrupt playback.
  Future<void> addTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    _queue.addAll(tracks);
    await _playlist.addAll(tracks.map((t) => AudioSource.file(t.filePath)).toList());
    queue.add(_queue.map(_trackToMediaItem).toList());
  }

  /// Restores a previously-saved library on app startup without
  /// auto-playing anything. Use this for loadQueue(); use setQueue() only
  /// when the user explicitly picks a track/playlist to play now.
  Future<void> loadQueueSilently(List<Track> tracks) async {
    _queue.clear();
    _queue.addAll(tracks);

    await _playlist.clear();
    await _playlist.addAll(tracks.map((t) => AudioSource.file(t.filePath)).toList());

    queue.add(_queue.map(_trackToMediaItem).toList());

    // เตรียมเพลงแรกไว้ให้พร้อม แต่ไม่เล่นอัตโนมัติ
    if (tracks.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  // ─── Overrides ───
  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  /// Removes the track at [index] from the queue and the underlying playlist.
  /// If the removed track is the currently playing one, just_audio auto-advances
  /// (or stops if it was the last item). When the queue becomes empty the player
  /// is stopped and the now-playing bar is cleared.
  Future<void> removeTrackAt(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _queue.removeAt(index);
    await _playlist.removeAt(index);
    queue.add(_queue.map(_trackToMediaItem).toList());

    if (_queue.isEmpty) {
      await _player.stop();
      mediaItem.add(null);
    }
  }

  /// Removes every track from the queue and stops playback.
  Future<void> clearQueue() async {
    await _player.stop();
    _queue.clear();
    await _playlist.clear();
    queue.add([]);
    mediaItem.add(null);
  }

  // ─── Helpers ───
  void _listenToPlayerState() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  void _listenToCurrentIndex() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        mediaItem.add(_trackToMediaItem(_queue[index]));
      }
    });
  }

  void _listenToDuration() {
    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      processingState: _mapProcessingState(_player.processingState),
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex ?? 0,
    );
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle: return AudioProcessingState.idle;
      case ProcessingState.loading: return AudioProcessingState.loading;
      case ProcessingState.buffering: return AudioProcessingState.buffering;
      case ProcessingState.ready: return AudioProcessingState.ready;
      case ProcessingState.completed: return AudioProcessingState.completed;
    }
  }

  MediaItem _trackToMediaItem(Track track) {
    return MediaItem(
      id: track.filePath,
      title: track.title,
      artist: track.displayArtist,
      duration: track.duration,
      artUri: track.albumArtPath != null ? Uri.file(track.albumArtPath!) : null,
    );
  }
}
