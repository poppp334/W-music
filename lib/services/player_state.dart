import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/track.dart';
import '../models/playlist.dart';
import 'audio_handler.dart';

enum WRepeatMode { off, one, all }

class PlayerState {
  final WAudioHandler _handler;
  static const _storageKey = 'saved_queue_paths';
  static const _playlistsKey = 'saved_playlists';
  static const _gridViewKey = 'grid_view_enabled';

  PlayerState(this._handler);

  /// Tracks whether the audio handler's internal queue matches the library
  /// (queue.value). When false (after playTracks from a playlist), playTrackAtIndex
  /// reloads the library into the handler before seeking.
  bool _libraryLoadedInHandler = true;

  // ─── Reactive State ───
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);
  final ValueNotifier<bool> shuffleEnabled = ValueNotifier(false);
  final ValueNotifier<WRepeatMode> repeatMode = ValueNotifier(WRepeatMode.off);
  final ValueNotifier<double> progress = ValueNotifier(0.0);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<Track?> currentTrack = ValueNotifier(null);
  final ValueNotifier<int> currentIndex = ValueNotifier(0);
  // queue = permanent library (shown in home_screen, persisted to SharedPreferences)
  final ValueNotifier<List<Track>> queue = ValueNotifier([]);
  // nowPlayingQueue = what the audio handler currently has loaded (playlist playback, etc.)
  final ValueNotifier<List<Track>> nowPlayingQueue = ValueNotifier([]);
  final ValueNotifier<List<Playlist>> playlists = ValueNotifier([]);
  final ValueNotifier<bool> isGridView = ValueNotifier(false);

  // ─── Persistence ───
  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final data = queue.value.map((t) => {
      'filePath': t.filePath,
      if (t.customTitle != null) 'customTitle': t.customTitle,
      if (t.customArtPath != null) 'customArtPath': t.customArtPath,
      if (t.customArtist != null) 'customArtist': t.customArtist,
    }).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
  }

  Future<void> loadQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try new JSON format first
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final validTracks = <Track>[];
            for (final entry in decoded) {
              if (entry is Map) {
                final filePath = entry['filePath'] as String?;
                if (filePath == null) continue;
                final file = File(filePath);
                if (!file.existsSync()) continue;
                final track = Track.fromFile(file);
                final customTitle = entry['customTitle'] as String?;
                final customArtPath = entry['customArtPath'] as String?;
                final customArtist = entry['customArtist'] as String?;
                if ((customTitle != null && customTitle.isNotEmpty) ||
                    (customArtPath != null && customArtPath.isNotEmpty) ||
                    (customArtist != null && customArtist.isNotEmpty)) {
                  validTracks.add(track.copyWith(
                    customTitle: (customTitle != null && customTitle.isNotEmpty)
                        ? customTitle
                        : null,
                    customArtPath: customArtPath,
                    customArtist: (customArtist != null && customArtist.isNotEmpty)
                        ? customArtist
                        : null,
                  ));
                } else {
                  validTracks.add(track);
                }
              } else if (entry is String) {
                final file = File(entry);
                if (file.existsSync()) {
                  validTracks.add(Track.fromFile(file));
                }
              }
            }
            if (validTracks.isNotEmpty) {
              await _handler.loadQueueSilently(validTracks);
              queue.value = validTracks;
              nowPlayingQueue.value = validTracks;
              _libraryLoadedInHandler = true;
            }
            return;
          }
        } catch (_) {
          // JSON decode failed — fall through to old-format attempt
        }
      }

      // Fallback: old format (StringList)
      final paths = prefs.getStringList(_storageKey) ?? [];
      if (paths.isEmpty) return;

      final validTracks = paths
          .map((p) => File(p))
          .where((file) => file.existsSync())
          .map((file) => Track.fromFile(file))
          .toList();

      if (validTracks.isNotEmpty) {
        await _handler.loadQueueSilently(validTracks);
        queue.value = validTracks;
        nowPlayingQueue.value = validTracks;
        _libraryLoadedInHandler = true;
        // Upgrade legacy flat-path storage to new JSON format
        // so the next restart reads custom overrides correctly.
        await _saveQueue();
      }
    } catch (e) {
      debugPrint('loadQueue error: $e');
      queue.value = [];
    }
  }

  // ─── Playlist Persistence ───
  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(
      playlists.value.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_playlistsKey, json);
  }

  Future<void> _loadPlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_playlistsKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as List<dynamic>;
      playlists.value = decoded
          .map((e) => Playlist.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      playlists.value = [];
    }
  }

  // ─── Playlist CRUD ───
  Future<void> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final playlist = Playlist(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: trimmed,
      createdAt: DateTime.now(),
    );
    playlists.value = [...playlists.value, playlist];
    await _savePlaylists();
  }

  Future<void> addToPlaylist(String playlistId, Track track) async {
    final updated = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      if (p.trackPaths.contains(track.filePath)) return p;
      return p.copyWith(trackPaths: [...p.trackPaths, track.filePath]);
    }).toList();
    playlists.value = updated;
    await _savePlaylists();
  }

  Future<void> removeFromPlaylist(String playlistId, String trackPath) async {
    final updated = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(
        trackPaths: p.trackPaths.where((t) => t != trackPath).toList(),
      );
    }).toList();
    playlists.value = updated;
    await _savePlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    playlists.value =
        playlists.value.where((p) => p.id != playlistId).toList();
    await _savePlaylists();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final updated = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(name: trimmed);
    }).toList();
    playlists.value = updated;
    await _savePlaylists();
  }

  // ─── Custom Metadata ───
  /// Sets or clears a custom display title for the track identified by [filePath].
  /// Passing an empty string or null resets to the original extracted title.
  Future<void> setTrackCustomTitle(String filePath, String? title) async {
    final trimmed = title?.trim();
    final effective = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
    queue.value = queue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customTitle: effective);
    }).toList();
    nowPlayingQueue.value = nowPlayingQueue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customTitle: effective);
    }).toList();
    await _saveQueue();
  }

  /// Sets or clears a custom album art path for the track identified by [filePath].
  /// Passing null clears the custom override and reverts to extracted art.
  Future<void> setTrackCustomArt(String filePath, String? artPath) async {
    queue.value = queue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customArtPath: artPath);
    }).toList();
    nowPlayingQueue.value = nowPlayingQueue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customArtPath: artPath);
    }).toList();
    await _saveQueue();
  }

  /// Sets or clears a custom artist override for the track identified by [filePath].
  /// Passing an empty string or null resets to the original extracted artist.
  Future<void> setTrackCustomArtist(String filePath, String? artist) async {
    final trimmed = artist?.trim();
    final effective = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;
    queue.value = queue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customArtist: effective);
    }).toList();
    nowPlayingQueue.value = nowPlayingQueue.value.map((t) {
      if (t.filePath != filePath) return t;
      return t.copyWith(customArtist: effective);
    }).toList();
    await _saveQueue();
  }

  /// Sets or clears a cover art image for the playlist identified by [playlistId].
  Future<void> setPlaylistCoverArt(String playlistId, String? artPath) async {
    final updated = playlists.value.map((p) {
      if (p.id != playlistId) return p;
      return p.copyWith(coverArtPath: artPath);
    }).toList();
    playlists.value = updated;
    await _savePlaylists();
  }

  // ─── View Mode ───
  Future<void> setGridView(bool value) async {
    isGridView.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gridViewKey, value);
  }

  Future<void> _loadGridViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isGridView.value = prefs.getBool(_gridViewKey) ?? false;
  }

  /// Loads tracks into the audio handler for playback without touching the
  /// permanent library (queue). Use this for playlist playback, shuffling
  /// a subset, etc. — anything that shouldn't overwrite the saved library.
  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    nowPlayingQueue.value = tracks;
    _libraryLoadedInHandler = false;
    await _handler.setQueue(tracks, startIndex: startIndex);
  }

  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    final tracks = resolvePlaylistTracks(playlist);
    if (tracks.isEmpty) return;
    await playTracks(tracks, startIndex: startIndex);
  }

  /// Resolves a [Playlist]'s stored file paths into actual [Track] objects
  /// by matching against the current library ([queue]). Paths that no longer
  /// exist in the library are silently skipped.
  List<Track> resolvePlaylistTracks(Playlist playlist) {
    final pathToTrack = {for (final t in queue.value) t.filePath: t};
    return playlist.trackPaths
        .map((path) => pathToTrack[path])
        .whereType<Track>()
        .toList();
  }

  // ─── Actions ───
  Future<void> setQueue(List<Track> tracks, {int startIndex = 0}) async {
    queue.value = tracks;
    nowPlayingQueue.value = tracks;
    _libraryLoadedInHandler = true;
    await _handler.setQueue(tracks, startIndex: startIndex);
    await _saveQueue();
  }

  Future<void> addToQueue(Track track) async {
    if (queue.value.any((t) => t.filePath == track.filePath)) return;

    queue.value = [...queue.value, track];
    nowPlayingQueue.value = [...nowPlayingQueue.value, track];
    _libraryLoadedInHandler = true;
    await _handler.addTrack(track);
    await _saveQueue();
  }

  /// Adds multiple tracks at once (e.g. from a file/folder import) without
  /// touching whatever is already in the queue or currently playing.
  /// This is what your "import songs" button should call instead of
  /// setQueue(), so each import appends to your local library like Spotify
  /// adds to a playlist, rather than replacing it.
  Future<void> addAllToQueue(List<Track> tracks) async {
    if (tracks.isEmpty) return;

    final existingPaths = queue.value.map((t) => t.filePath).toSet();
    final newTracks = tracks.where((t) => !existingPaths.contains(t.filePath)).toList();
    if (newTracks.isEmpty) return;

    queue.value = [...queue.value, ...newTracks];
    nowPlayingQueue.value = [...nowPlayingQueue.value, ...newTracks];
    _libraryLoadedInHandler = true;
    await _handler.addTracks(newTracks);
    await _saveQueue();
  }

  /// Removes the track at [index] from the library and persists the change.
  Future<void> removeTrack(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    _deleteArtFile(queue.value[index].albumArtPath);
    final updated = [...queue.value]..removeAt(index);
    queue.value = updated;
    if (index < nowPlayingQueue.value.length) {
      final npq = [...nowPlayingQueue.value]..removeAt(index);
      nowPlayingQueue.value = npq;
    }
    _libraryLoadedInHandler = true;
    await _handler.removeTrackAt(index);
    await _saveQueue();
  }

  /// Removes every track, stops playback, and persists the empty library.
  Future<void> clearLibrary() async {
    for (final track in queue.value) {
      _deleteArtFile(track.albumArtPath);
    }
    queue.value = [];
    nowPlayingQueue.value = [];
    _libraryLoadedInHandler = true;
    await _handler.clearQueue();
    await _saveQueue();
  }

  static void _deleteArtFile(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Silently ignore deletion failures (e.g. permission issues)
    }
  }

  Future<void> togglePlayPause() async {
    if (_handler.playbackState.value.playing) {
      await _handler.pause();
    } else {
      await _handler.play();
    }
  }

  Future<void> skipToNext() async => _handler.skipToNext();
  Future<void> skipToPrevious() async => _handler.skipToPrevious();
  Future<void> seekTo(Duration position) async => _handler.seek(position);

  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    if (!_libraryLoadedInHandler) {
      await _handler.setQueue(queue.value, startIndex: index);
      nowPlayingQueue.value = queue.value;
      _libraryLoadedInHandler = true;
    } else {
      await _handler.skipToQueueItem(index);
    }
  }

  Future<void> toggleShuffle() async {
    shuffleEnabled.value = !shuffleEnabled.value;
    _handler.setShuffleMode(shuffleEnabled.value ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none);
  }

  void cycleRepeatMode() {
    if (repeatMode.value == WRepeatMode.off) repeatMode.value = WRepeatMode.one;
    else if (repeatMode.value == WRepeatMode.one) repeatMode.value = WRepeatMode.all;
    else repeatMode.value = WRepeatMode.off;

    _handler.setRepeatMode(repeatMode.value == WRepeatMode.one
    ? AudioServiceRepeatMode.one
    : (repeatMode.value == WRepeatMode.all ? AudioServiceRepeatMode.all : AudioServiceRepeatMode.none));
  }

  // ─── Streams ───
  Stream<PositionData> get positionDataStream => Rx.combineLatest3<Duration, Duration, bool, PositionData>(
    _handler.positionStream,
    _handler.mediaItem.map((item) => item?.duration ?? Duration.zero),
    _handler.playbackState.map((state) => state.playing),
    (pos, dur, playing) => PositionData(position: pos, duration: dur, isPlaying: playing));

  // ─── Init & Dispose ───
  late final List<StreamSubscription> _subscriptions;

  Future<void> init() async {
    await Future.wait([loadQueue(), _loadPlaylists(), _loadGridViewPreference()]);
    _subscriptions = [
      _handler.playbackState.listen((s) => isPlaying.value = s.playing),
      _handler.positionStream.listen((p) => position.value = p),
      _handler.durationStream.listen((d) => duration.value = d ?? Duration.zero),
      _handler.mediaItem.listen((item) {
        if (item != null) {
          currentIndex.value = _handler.currentIndex;
          if (currentIndex.value >= 0 &&
              currentIndex.value < nowPlayingQueue.value.length) {
            currentTrack.value =
                nowPlayingQueue.value[currentIndex.value];
          } else if (currentIndex.value >= 0 &&
              currentIndex.value < queue.value.length) {
            currentTrack.value = queue.value[currentIndex.value];
          }
        }
      }),
    ];
  }

  void dispose() {
    for (final sub in _subscriptions) sub.cancel();
  }
}

// ─── Data Classes ───
class PositionData {
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  const PositionData({required this.position, required this.duration, required this.isPlaying});
}
