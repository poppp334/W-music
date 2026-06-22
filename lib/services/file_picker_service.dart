import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/track.dart';

class FilePickerService {
  static const _audioExtensions = ['mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg', 'opus'];

  Future<bool> requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // สำหรับ Android 13 ขึ้นไปใช้ Permission.audio
        final status = await Permission.audio.request();
        if (status.isGranted) return true;
        return (await Permission.storage.request()).isGranted;
      }
      return true;
    } catch (e) {
      debugPrint("Permission error: $e");
      return false;
    }
  }

  Future<List<Track>> pickAudioFiles() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return [];

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _audioExtensions,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final files = result.files.where((f) => f.path != null).map((f) => File(f.path!));
      return _extractTracks(files);
    } catch (e) {
      debugPrint("File picking error: $e");
      return [];
    }
  }

  Future<List<Track>> pickAudioDirectory() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return [];

      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) return [];

      final directory = Directory(dirPath);
      if (!directory.existsSync()) return [];

      final audioFiles = directory.listSync(recursive: true)
        .whereType<File>()
        .where((file) => _audioExtensions.contains(file.path.split('.').last.toLowerCase()));
      return _extractTracks(audioFiles);
    } catch (e) {
      debugPrint("Directory scanning error: $e");
      return [];
    }
  }

  /// Creates [Track]s with extracted album art, processing one file at a time
  /// to avoid blocking the UI on large imports.
  Future<List<Track>> _extractTracks(Iterable<File> files) async {
    final tracks = <Track>[];
    for (final file in files) {
      tracks.add(await Track.fromFileWithArt(file));
    }
    return tracks;
  }
}
