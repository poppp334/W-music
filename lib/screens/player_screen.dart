import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/player_state.dart';
import '../theme/stitch_theme.dart';
import '../widgets/glass_container.dart';

/// Full-screen player view with blurred album-art backdrop and glass controls.
class PlayerScreen extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback onClose;

  const PlayerScreen({
    super.key,
    required this.playerState,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WTheme.background,
      body: ValueListenableBuilder(
        valueListenable: playerState.currentTrack,
        builder: (context, Track? track, _) {
          return Stack(
            children: [
              // Blurred album art backdrop
              if (track?.displayArtPath != null)
                Positioned.fill(
                  child: Image.file(
                    File(track!.displayArtPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              // Heavy blur + dark overlay
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(
                      color: WTheme.background.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(onClose: onClose),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WTheme.gutter * 2,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _AlbumArt(track: track),
                            const SizedBox(height: 32),
                            Text(
                              track?.displayTitle ?? 'Nothing playing',
                              style: WTheme.displayMedium,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track?.displayArtist ?? '—',
                              style: WTheme.bodyLarge.copyWith(
                                color: WTheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            _ProgressSection(playerState: playerState),
                            const SizedBox(height: 24),
                            _Controls(playerState: playerState),
                            const SizedBox(height: 16),
                            _SecondaryControls(playerState: playerState),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onClose;
  const _TopBar({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WTheme.gutter,
        vertical: 8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            iconSize: 32,
          ),
          const Spacer(),
          Text('Now Playing', style: WTheme.labelLarge),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final Track? track;
  const _AlbumArt({required this.track});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(WTheme.cardRadius * 2),
        child: track?.displayArtPath != null
            ? Image.file(
                File(track!.displayArtPath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback,
              )
            : _fallback,
      ),
    );
  }

  Widget get _fallback => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WTheme.accent.withValues(alpha: 0.3),
              WTheme.surfaceVariant,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.music_note_rounded,
            size: 96,
            color: WTheme.accent,
          ),
        ),
      );
}

class _ProgressSection extends StatelessWidget {
  final PlayerState playerState;
  const _ProgressSection({required this.playerState});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PositionData>(
      stream: playerState.positionDataStream,
      builder: (context, snapshot) {
        final data = snapshot.data ??
            const PositionData(
              position: Duration.zero,
              duration: Duration.zero,
              isPlaying: false,
            );
        final position = data.position;
        final duration = data.duration;
        final maxMs = duration.inMilliseconds == 0
            ? 1.0
            : duration.inMilliseconds.toDouble();
        final value =
            position.inMilliseconds.clamp(0, maxMs.toInt()).toDouble();

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: WTheme.accent,
                inactiveTrackColor: WTheme.disabled,
                thumbColor: WTheme.accent,
                overlayColor: WTheme.accent.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: maxMs,
                onChanged: (v) {
                  playerState.seekTo(Duration(milliseconds: v.toInt()));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position), style: WTheme.bodySmall),
                  Text(_format(duration), style: WTheme.bodySmall),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Controls extends StatelessWidget {
  final PlayerState playerState;
  const _Controls({required this.playerState});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 12,
      radius: WTheme.buttonRadius * 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: playerState.skipToPrevious,
              icon: const Icon(Icons.skip_previous_rounded),
              iconSize: 32,
              color: WTheme.onBackground,
            ),
            ValueListenableBuilder<bool>(
              valueListenable: playerState.isPlaying,
              builder: (context, playing, _) {
                return _PlayPauseButton(
                  playing: playing,
                  onPressed: playerState.togglePlayPause,
                );
              },
            ),
            IconButton(
              onPressed: playerState.skipToNext,
              icon: const Icon(Icons.skip_next_rounded),
              iconSize: 32,
              color: WTheme.onBackground,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  final bool playing;
  final VoidCallback onPressed;
  const _PlayPauseButton({required this.playing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: WTheme.touchTarget,
      height: WTheme.touchTarget,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: WTheme.accent,
          foregroundColor: Colors.black,
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Icon(
          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 32,
        ),
      ),
    );
  }
}

class _SecondaryControls extends StatelessWidget {
  final PlayerState playerState;
  const _SecondaryControls({required this.playerState});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 12,
      radius: WTheme.buttonRadius * 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: playerState.shuffleEnabled,
              builder: (context, enabled, _) {
                return IconButton(
                  onPressed: playerState.toggleShuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  color: enabled
                      ? WTheme.accent
                      : WTheme.onSurfaceVariant,
                  tooltip: 'Shuffle',
                );
              },
            ),
            ValueListenableBuilder<WRepeatMode>(
              valueListenable: playerState.repeatMode,
              builder: (context, mode, _) {
                return IconButton(
                  onPressed: playerState.cycleRepeatMode,
                  icon: Icon(_repeatIcon(mode)),
                  color: mode == WRepeatMode.off
                      ? WTheme.onSurfaceVariant
                      : WTheme.accent,
                  tooltip: 'Repeat',
                );
              },
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.favorite_border_rounded),
              color: WTheme.onSurfaceVariant,
              tooltip: 'Favorite',
            ),
          ],
        ),
      ),
    );
  }

  IconData _repeatIcon(WRepeatMode mode) {
    switch (mode) {
      case WRepeatMode.one:
        return Icons.repeat_one_rounded;
      case WRepeatMode.all:
      case WRepeatMode.off:
        return Icons.repeat_rounded;
    }
  }
}
