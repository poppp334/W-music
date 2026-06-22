import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ImageImportResult {
  final String? path;
  final String? error;
  const ImageImportResult({this.path, this.error});
  bool get isSuccess => path != null;
  bool get isError => error != null;
}

class ImageImportService {
  static const _maxBytes = 20 * 1024 * 1024;
  static const _connectTimeout = Duration(seconds: 15);

  static const _imageContentTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/bmp',
  ];

  static const _validExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp',
  ];

  /// Pick an image from the device gallery.
  /// Copies the selection into app documents with a hash-based filename
  /// (deduplicates re-imports). Returns the saved path or null on cancel/failure.
  static Future<String?> pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;

      final cacheDir = await getApplicationDocumentsDirectory();
      final originalPath = picked.path;
      final ext = _extensionFromPath(originalPath);
      final safeExt = _validExtensions.contains(ext) ? ext : 'jpg';
      final hashName = 'img_${originalPath.hashCode.toRadixString(16)}.$safeExt';
      final destPath = '${cacheDir.path}/$hashName';
      final destFile = File(destPath);

      if (destFile.existsSync()) return destPath;

      await File(originalPath).copy(destPath);
      return destPath;
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  /// Download an image from a URL and cache it locally.
  /// Validates content-type starts with `image/`, caps at 20MB, streams to
  /// a `.tmp` file then renames on success. Returns the saved path on success
  /// or an error message on failure.
  static Future<ImageImportResult> importFromUrl(String url) async {
    File? file;

    try {
      final uri = Uri.tryParse(url);
      if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        return const ImageImportResult(
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
          return const ImageImportResult(
            error: 'Connection timed out. Check the URL and try again.',
          );
        }

        if (response.statusCode != 200) {
          return ImageImportResult(
            error: 'The server returned an error (HTTP ${response.statusCode}).',
          );
        }

        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.startsWith('image/')) {
          return ImageImportResult(
            error: contentType.isEmpty
                ? 'This doesn\'t look like a direct image file (no content type).'
                : 'The server returned "$contentType", not an image.',
          );
        }

        final contentLength = response.contentLength ?? -1;
        if (contentLength > _maxBytes) {
          return const ImageImportResult(
            error: 'The image is too large (max 20 MB).',
          );
        }

        final docsDir = await getApplicationDocumentsDirectory();
        final ext = _extensionFromContentType(contentType, url);
        final fileName = 'url_img_${url.hashCode.toRadixString(16)}.$ext';
        final finalPath = '${docsDir.path}/$fileName';
        final tempPath = '$finalPath.tmp';

        file = File(tempPath);
        final sink = file.openWrite();
        int received = 0;
        try {
          await for (final chunk in response.stream) {
            sink.add(chunk);
            received += chunk.length;

            if (received > _maxBytes) {
              throw const HttpException('Image exceeds 20 MB limit');
            }
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        await file.rename(finalPath);
        return ImageImportResult(path: finalPath);
      } finally {
        client.close();
      }
    } on SocketException {
      await _cleanupFile(file);
      return const ImageImportResult(
        error: 'Could not reach the server. Check the URL and try again.',
      );
    } on HttpException catch (e) {
      await _cleanupFile(file);
      return ImageImportResult(error: e.message);
    } catch (e) {
      await _cleanupFile(file);
      final msg = e.toString();
      if (msg.contains('TimeoutException') || msg.contains('timed out')) {
        return const ImageImportResult(
          error: 'Connection timed out. Check the URL and try again.',
        );
      }
      debugPrint('Image URL import error: $e');
      return const ImageImportResult(
        error: 'Import failed. Check the URL and try again.',
      );
    }
  }

  static Future<void> _cleanupFile(File? file) async {
    if (file != null && file.existsSync()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  static String _extensionFromContentType(String contentType, String url) {
    for (final ct in _imageContentTypes) {
      if (contentType.startsWith(ct)) {
        return ct.split('/').last;
      }
    }
    return _extensionFromPath(url);
  }

  static String _extensionFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot > 0 && dot < path.length - 1) {
      return path.substring(dot + 1).toLowerCase();
    }
    return 'jpg';
  }
}
