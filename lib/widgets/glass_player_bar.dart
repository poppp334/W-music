import 'dart:io';

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/player_state.dart';
import '../theme/stitch_theme.dart';
import 'glass_container.dart';

/// Glassmorphism floating mini-player bar that sits at the bottom of the screen.
class GlassPlayerBar extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback? onTap;

  const GlassPlayerBar({
    super.key,
    required this.playerState,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: WTheme.gutter,
          vertical: 8,
        ),
        child: GlassContainer(
          blur: 20,
          radius: WTheme.cardRadius,
          color: WTheme.glassSurfaceStrong,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: playerState.progress,
              builder: (context, progress, _) {
                return _ProgressLine(progress: progress);
              },
            ),
            ValueListenableBuilder<Track?>(
              valueListenable: playerState.currentTrack,
              builder: (context, track, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WTheme.gutter,
                  ),
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      children: [
                        _AlbumArtThumbnail(track: track),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track?.displayTitle ?? 'Unknown track',
                                style: WTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track?.displayArtist ?? 'Unknown artist',
                                style: WTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        ValueListenableBuilder<bool>(
                          valueListenable: playerState.isPlaying,
                          builder: (context, isPlaying, _) {
                            return IconButton(
                              onPressed: playerState.togglePlayPause,
                              icon: Icon(
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: WTheme.onBackground,
                                size: 32,
                              ),
                              style: IconButton.styleFrom(
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          onPressed: playerState.skipToNext,
                          icon: const Icon(
                            Icons.skip_next_rounded,
                            color: WTheme.onSurfaceVariant,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final double progress;
  const _ProgressLine({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.transparent,
        valueColor: const AlwaysStoppedAnimation(WTheme.accent),
      ),
    );
  }
}

class _AlbumArtThumbnail extends StatelessWidget {
  final Track? track;
  const _AlbumArtThumbnail({required this.track});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
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
        decoration: const BoxDecoration(
          color: WTheme.surfaceVariant,
        ),
        child: const Icon(
          Icons.music_note_rounded,
          color: WTheme.accent,
          size: 24,
        ),
      );
}
