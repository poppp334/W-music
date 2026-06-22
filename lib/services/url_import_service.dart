import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/track.dart';

class UrlImportResult {
  final Track? track;
  final String? error;
  const UrlImportResult({this.track, this.error});
  bool get isSuccess => track != null;
  bool get isError => error != null;
}

class UrlImportService {
  static const _maxBytes = 500 * 1024 * 1024;
  static const _connectTimeout = Duration(seconds: 15);

  static const _contentTypeMap = <String, String>{
    'audio/mpeg': 'mp3',
    'audio/mp3': 'mp3',
    'audio/mp4': 'm4a',
    'audio/x-m4a': 'm4a',
    'audio/aac': 'aac',
    'audio/wav': 'wav',
    'audio/x-wav': 'wav',
    'audio/wave': 'wav',
    'audio/flac': 'flac',
    'audio/x-flac': 'flac',
    'audio/ogg': 'ogg',
    'audio/opus': 'opus',
  };

  static const _knownExtensions = [
    'mp3', 'm4a', 'wav', 'flac', 'aac', 'ogg', 'opus',
  ];

  Future<UrlImportResult> importFromUrl(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    File? file;

    try {
      final uri = Uri.tryParse(url);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return const UrlImportResult(
          error: 'Please enter a valid http or https URL.',
        );
      }

      final client = http.Client();

      try {
        final request = http.Request('GET', uri);
        final http.StreamedResponse response;
        try {
          response = await client.send(request).timeout(_connectTimeout);
        } on TimeoutException {
          return const UrlImportResult(
            error: 'Connection timed out. Check the URL and try again.',
          );
        }

        if (response.statusCode != 200) {
          return UrlImportResult(
            error: 'The server returned an error (HTTP ${response.statusCode}).',
          );
        }

        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.startsWith('audio/')) {
          return UrlImportResult(
            error: contentType.isEmpty
                ? 'This doesn\'t look like a direct audio file '
                    '(no content type).'
                : 'This doesn\'t look like a direct audio file. '
                    'Server returned "$contentType".',
          );
        }

        final docsDir = await getApplicationDocumentsDirectory();
        final ext = _extensionFromContentType(contentType, url);
        final fileName = 'url_${url.hashCode.toRadixString(16)}.$ext';
        final finalPath = '${docsDir.path}/$fileName';
        final tempPath = '$finalPath.tmp';

        final contentLength = response.contentLength ?? -1;

        if (contentLength > _maxBytes) {
          return const UrlImportResult(
            error: 'The file is too large (max 500 MB).',
          );
        }

        file = File(tempPath);
        final sink = file.openWrite();
        int received = 0;
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            received += chunk.length;

            if (received > _maxBytes) {
              throw const HttpException('File exceeds 500 MB limit');
            }

            if (onProgress != null && contentLength > 0) {
              onProgress(received / contentLength);
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        await file.rename(finalPath);

        final track = await Track.fromFileWithArt(File(finalPath));
        return UrlImportResult(track: track);
      } finally {
        client.close();
      }
    } on SocketException {
      await _cleanupFile(file);
      return const UrlImportResult(
        error: 'Could not reach the server. Check the URL and try again.',
      );
    } on HttpException catch (e) {
      await _cleanupFile(file);
      return UrlImportResult(error: e.message);
    } catch (e) {
      await _cleanupFile(file);
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        return const UrlImportResult(
          error: 'Connection timed out. Check the URL and try again.',
        );
      }
      debugPrint('URL import error: $e');
      return const UrlImportResult(
        error: 'Import failed. Check the URL and try again.',
      );
    }
  }

  Future<void> _cleanupFile(File? file) async {
    if (file != null && file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static String _extensionFromContentType(String contentType, String url) {
    for (final entry in _contentTypeMap.entries) {
      if (contentType.startsWith(entry.key)) return entry.value;
    }
    final uri = Uri.tryParse(url);
    if (uri != null) {
      final path = uri.path;
      final dot = path.lastIndexOf('.');
      if (dot > 0 && dot < path.length - 1) {
        final ext = path.substring(dot + 1).toLowerCase();
        if (_knownExtensions.contains(ext)) return ext;
      }
    }
    return 'mp3';
  }
}
