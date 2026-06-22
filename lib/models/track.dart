import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Represents a single track in the music library.
class Track {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration? duration;
  final String filePath;
  final String? albumArtPath;
  final String? customTitle;
  final String? customArtPath;
  final String? customArtist;

  /// Returns the effective display title: custom override if set, else original.
  String get displayTitle => customTitle ?? title;

  /// Returns the effective display artist: custom override if set, else original.
  String get displayArtist => customArtist ?? artist;

  /// Returns the effective display art path: custom override if set, else original.
  String? get displayArtPath => customArtPath ?? albumArtPath;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    required this.filePath,
    this.albumArtPath,
    this.customTitle,
    this.customArtPath,
    this.customArtist,
  });

  /// Create a Track from a file path with basic metadata extraction.
  factory Track.fromFile(File file, {String? title, String? artist}) {
    final fileName = file.path.split('/').last;
    final nameWithoutExt = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    return Track(
      id: file.path,
      title: title ?? nameWithoutExt,
      artist: artist ?? 'Unknown Artist',
      filePath: file.path,
    );
  }

  /// Creates a Track and extracts embedded album art, caching it to disk.
  /// Uses a hash-based filename so re-importing the same file reuses the cache.
  /// Also uses embedded title/artist when available.
  static Future<Track> fromFileWithArt(File file) async {
    final base = Track.fromFile(file);
    try {
      final cacheDir = await getApplicationDocumentsDirectory();
      final artFile = File(
        '${cacheDir.path}/art_${file.path.hashCode.toRadixString(16)}.jpg',
      );

      final metadata = readMetadata(file, getImage: true);

      final metaTitle = metadata.title;
      final metaArtist = metadata.artist;
      final overrides = <String, dynamic>{};
      if (metaTitle != null && metaTitle.isNotEmpty) overrides['title'] = metaTitle;
      if (metaArtist != null && metaArtist.isNotEmpty) overrides['artist'] = metaArtist;

      if (artFile.existsSync()) {
        return base.copyWith(
          albumArtPath: artFile.path,
          title: metaTitle,
          artist: metaArtist,
        );
      }

      final picture =
          metadata.pictures.isNotEmpty ? metadata.pictures.first : null;
      if (picture != null) {
        await artFile.writeAsBytes(picture.bytes);
        return base.copyWith(
          albumArtPath: artFile.path,
          title: metaTitle,
          artist: metaArtist,
        );
      }

      if (metaTitle != null || metaArtist != null) {
        return base.copyWith(title: metaTitle, artist: metaArtist);
      }
    } catch (e) {
      debugPrint('Album art extraction error: $e');
    }
    return base;
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? filePath,
    String? albumArtPath,
    String? customTitle,
    String? customArtPath,
    String? customArtist,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      customTitle: customTitle ?? this.customTitle,
      customArtPath: customArtPath ?? this.customArtPath,
      customArtist: customArtist ?? this.customArtist,
    );
  }
}
