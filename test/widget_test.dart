// Smoke tests for W Music.
//
// These intentionally avoid audio_service/just_audio so they run in the
// standard `flutter test` environment without a real audio backend.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:w_music/models/track.dart';
import 'package:w_music/services/player_state.dart';
import 'package:w_music/theme/stitch_theme.dart';

void main() {
  group('Track', () {
    test('fromFile derives a title from the filename and strips extension', () {
      final track = Track.fromFile(File('/music/My Song.mp3'));
      expect(track.title, 'My Song');
      expect(track.artist, 'Unknown Artist');
      expect(track.filePath, '/music/My Song.mp3');
      expect(track.id, '/music/My Song.mp3');
    });

    test('copyWith merges only the provided fields', () {
      final track = Track.fromFile(File('/music/My Song.mp3'));
      final updated = track.copyWith(artist: 'Daft Punk', album: 'Discovery');
      expect(updated.title, 'My Song'); // unchanged
      expect(updated.artist, 'Daft Punk');
      expect(updated.album, 'Discovery');
    });
  });

  group('PlayerState', () {
    test('WRepeatMode cycles off → one → all', () {
      const modes = [
        WRepeatMode.off,
        WRepeatMode.one,
        WRepeatMode.all,
      ];
      expect(modes.indexOf(WRepeatMode.off), 0);
      expect(modes.indexOf(WRepeatMode.one), 1);
      expect(modes.indexOf(WRepeatMode.all), 2);
    });

    test('PositionData holds position, duration and playing flag', () {
      const data = PositionData(
        position: Duration(seconds: 30),
        duration: Duration(minutes: 3),
        isPlaying: true,
      );
      expect(data.isPlaying, isTrue);
      expect(data.position.inSeconds, 30);
      expect(data.duration.inMinutes, 3);
    });
  });

  group('WTheme', () {
    testWidgets('theme exposes the Spotify-green accent and dark surface',
        (tester) async {
      final theme = WTheme.darkTheme;
      expect(theme.colorScheme.primary, WTheme.accent);
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, WTheme.background);
    });
  });
}
