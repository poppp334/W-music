import 'dart:io';

import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/track.dart';
import '../services/image_import_service.dart';
import '../services/player_state.dart';
import '../theme/stitch_theme.dart';
import '../widgets/glass_container.dart';

class PlaylistsScreen extends StatefulWidget {
  final PlayerState playerState;
  final VoidCallback onClose;
  final VoidCallback onOpenPlayer;

  const PlaylistsScreen({
    super.key,
    required this.playerState,
    required this.onClose,
    required this.onOpenPlayer,
  });

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  Playlist? _selectedPlaylist;

  @override
  Widget build(BuildContext context) {
    if (_selectedPlaylist != null) {
      return _PlaylistDetailScreen(
        playlist: _selectedPlaylist!,
        playerState: widget.playerState,
        onOpenPlayer: widget.onOpenPlayer,
        onBack: () => setState(() => _selectedPlaylist = null),
      );
    }

    return Scaffold(
      backgroundColor: WTheme.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<Playlist>>(
          valueListenable: widget.playerState.playlists,
          builder: (context, playlists, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: widget.playerState.isGridView,
              builder: (context, isGrid, _) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        onClose: widget.onClose,
                        isGridView: isGrid,
                        onToggleView: () =>
                            widget.playerState.setGridView(!isGrid),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _CreateButton(
                        onCreate: (name) =>
                            widget.playerState.createPlaylist(name),
                      ),
                    ),
                    if (playlists.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else if (isGrid)
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WTheme.gutter,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final playlist = playlists[index];
                              final resolved = widget.playerState
                                  .resolvePlaylistTracks(playlist);
                              return _PlaylistGridCard(
                                playlist: playlist,
                                trackCount: resolved.length,
                                onTap: () => setState(
                                    () => _selectedPlaylist = playlist),
                              );
                            },
                            childCount: playlists.length,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WTheme.gutter,
                        ),
                        sliver: SliverList.separated(
                          itemCount: playlists.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            final resolved =
                                widget.playerState.resolvePlaylistTracks(playlist);
                            return _PlaylistCard(
                              playlist: playlist,
                              trackCount: resolved.length,
                              onTap: () =>
                                  setState(() => _selectedPlaylist = playlist),
                            );
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Header ───

class _Header extends StatelessWidget {
  final VoidCallback onClose;
  final bool isGridView;
  final VoidCallback onToggleView;

  const _Header({
    required this.onClose,
    required this.isGridView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WTheme.gutter,
        WTheme.gutter,
        WTheme.gutter,
        WTheme.sectionMargin,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: WTheme.onSurface,
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Text('Playlists', style: WTheme.displayMedium),
          const Spacer(),
          IconButton(
            onPressed: onToggleView,
            icon: Icon(
              isGridView
                  ? Icons.list_rounded
                  : Icons.grid_view_rounded,
              color: WTheme.accent,
            ),
            tooltip: isGridView ? 'List view' : 'Grid view',
          ),
        ],
      ),
    );
  }
}

// ─── Create Button ───

class _CreateButton extends StatelessWidget {
  final void Function(String name) onCreate;
  const _CreateButton({required this.onCreate});

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        var creating = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> doCreate() async {
              final name = controller.text.trim();
              if (name.isEmpty || creating) return;
              creating = true;
              setState(() {});
              onCreate(name);
              if (ctx.mounted) Navigator.of(ctx).pop();
            }

            return AlertDialog(
              title: const Text('New Playlist'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Playlist name...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: creating ? null : (_) => doCreate(),
              ),
              actions: [
                if (!creating)
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                if (!creating)
                  FilledButton(
                    onPressed: doCreate,
                    child: const Text('Create'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WTheme.gutter,
        vertical: 8,
      ),
      child: OutlinedButton.icon(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('New Playlist'),
        style: OutlinedButton.styleFrom(
          foregroundColor: WTheme.accent,
          side: const BorderSide(color: WTheme.accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(WTheme.buttonRadius),
          ),
        ),
      ),
    );
  }
}

// ─── Playlist Card (List) ───

class _PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int trackCount;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.trackCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 6,
      radius: WTheme.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: _artWidget(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      style: WTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
                      style: WTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: WTheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artWidget() {
    if (playlist.coverArtPath != null) {
      return Image.file(
        File(playlist.coverArtPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback,
      );
    }
    return _fallback;
  }

  Widget get _fallback => Container(
        decoration: const BoxDecoration(
          color: WTheme.surfaceVariant,
        ),
        child: const Icon(
          Icons.queue_music_rounded,
          color: WTheme.accent,
          size: 28,
        ),
      );
}

// ─── Playlist Grid Card ───

class _PlaylistGridCard extends StatelessWidget {
  final Playlist playlist;
  final int trackCount;
  final VoidCallback onTap;

  const _PlaylistGridCard({
    required this.playlist,
    required this.trackCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 6,
      radius: WTheme.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _artWidget(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                playlist.name,
                style: WTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
                style: WTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artWidget() {
    if (playlist.coverArtPath != null) {
      return Image.file(
        File(playlist.coverArtPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback,
      );
    }
    return _fallback;
  }

  Widget get _fallback => Container(
        decoration: const BoxDecoration(
          color: WTheme.surfaceVariant,
        ),
        child: const Center(
          child: Icon(
            Icons.queue_music_rounded,
            color: WTheme.accent,
            size: 32,
          ),
        ),
      );
}

// ─── Empty State ───

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: WTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(
                Icons.queue_music_rounded,
                color: WTheme.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No playlists yet',
              style: WTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a playlist to organize your music.',
              style: WTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Playlist Detail Screen ───

class _PlaylistDetailScreen extends StatelessWidget {
  final Playlist playlist;
  final PlayerState playerState;
  final VoidCallback onOpenPlayer;
  final VoidCallback onBack;

  const _PlaylistDetailScreen({
    required this.playlist,
    required this.playerState,
    required this.onOpenPlayer,
    required this.onBack,
  });

  void _play(BuildContext context) {
    final resolved = playerState.resolvePlaylistTracks(playlist);
    if (resolved.isEmpty) return;
    playerState.playPlaylist(playlist);
    onOpenPlayer();
  }

  Future<void> _removeTrack(String trackPath) async {
    await playerState.removeFromPlaylist(playlist.id, trackPath);
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(text: playlist.name);
    showDialog(
      context: context,
      builder: (ctx) {
        var renaming = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> doRename() async {
              final name = controller.text.trim();
              if (name.isEmpty || renaming) return;
              renaming = true;
              setState(() {});
              await playerState.renamePlaylist(playlist.id, name);
              if (ctx.mounted) Navigator.of(ctx).pop();
            }

            return AlertDialog(
              title: const Text('Rename Playlist'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Playlist name...',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
                onSubmitted: renaming ? null : (_) => doRename(),
              ),
              actions: [
                if (!renaming)
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                if (!renaming)
                  FilledButton(
                    onPressed: doRename,
                    child: const Text('Rename'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCoverArtDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _CoverArtEditDialog(
        playlist: playlist,
        onSave: (path) async {
          await playerState.setPlaylistCoverArt(playlist.id, path);
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text(
          'Delete "${playlist.name}"? The tracks in your library are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              playerState.deletePlaylist(playlist.id);
              onBack();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = playerState.resolvePlaylistTracks(playlist);

    return Scaffold(
      backgroundColor: WTheme.background,
      appBar: AppBar(
        backgroundColor: WTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: WTheme.onSurface),
          onPressed: onBack,
        ),
        title: Text(playlist.name, style: WTheme.titleLarge),
        actions: [
          PopupMenuButton<void>(
            icon: const Icon(Icons.more_vert_rounded,
                color: WTheme.onSurfaceVariant),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => _showRenameDialog(context),
                child: const Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Rename'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _showCoverArtDialog(context),
                child: const Row(
                  children: [
                    Icon(Icons.image_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Cover art'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _showDeleteConfirm(context),
                child: const Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (resolved.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  WTheme.gutter,
                  8,
                  WTheme.gutter,
                  16,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _play(context),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play'),
                    style: FilledButton.styleFrom(
                      backgroundColor: WTheme.accent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(WTheme.buttonRadius),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: resolved.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No playable tracks.\n'
                          'Add tracks from your library.',
                          style: WTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(
                        left: WTheme.gutter,
                        right: WTheme.gutter,
                        bottom: 100,
                      ),
                      itemCount: resolved.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final track = resolved[index];
                        return _PlaylistTrackTile(
                          track: track,
                          isCurrent:
                              playerState.currentTrack.value?.filePath ==
                                  track.filePath,
                          onTap: () async {
                            await playerState.playPlaylist(playlist,
                                startIndex: index);
                            onOpenPlayer();
                          },
                          onRemove: () => _removeTrack(track.filePath),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Playlist Track Tile ───

class _PlaylistTrackTile extends StatelessWidget {
  final Track track;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PlaylistTrackTile({
    required this.track,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
  });

  Widget get _fallbackIcon => Icon(
        isCurrent ? Icons.equalizer_rounded : Icons.music_note_rounded,
        color: isCurrent ? WTheme.accent : WTheme.onSurfaceVariant,
        size: 24,
      );

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 6,
      radius: WTheme.cardRadius,
      color: isCurrent
          ? WTheme.glassSurfaceStrong
          : WTheme.glassSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: track.displayArtPath != null
                      ? Image.file(
                          File(track.displayArtPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _fallbackIcon,
                        )
                      : _fallbackIcon,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.displayTitle,
                      style: WTheme.titleSmall.copyWith(
                        color: isCurrent
                            ? WTheme.accent
                            : WTheme.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.displayArtist,
                      style: WTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<void>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: WTheme.onSurfaceVariant,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'More',
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: onRemove,
                    child: const Row(
                      children: [
                        Icon(Icons.remove_circle_outline_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Remove from playlist'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Cover Art Edit Dialog (Playlist) ───

class _CoverArtEditDialog extends StatefulWidget {
  final Playlist playlist;
  final Future<void> Function(String? path) onSave;

  const _CoverArtEditDialog({
    required this.playlist,
    required this.onSave,
  });

  @override
  State<_CoverArtEditDialog> createState() => _CoverArtEditDialogState();
}

class _CoverArtEditDialogState extends State<_CoverArtEditDialog> {
  String? _artPath;

  @override
  void initState() {
    super.initState();
    _artPath = widget.playlist.coverArtPath;
  }

  Future<void> _pickFromGallery() async {
    final path = await ImageImportService.pickFromGallery();
    if (path != null && mounted) {
      setState(() => _artPath = path);
    }
  }

  void _showUrlImportDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        var importing = false;
        var error = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> doImport() async {
              final url = urlController.text.trim();
              if (url.isEmpty || importing) return;
              importing = true;
              setState(() => error = '');
              final result = await ImageImportService.importFromUrl(url);
              if (!ctx.mounted) return;
              if (result.isSuccess) {
                Navigator.of(ctx).pop(result.path);
              } else {
                setState(() {
                  importing = false;
                  error = result.error ?? 'Import failed.';
                });
              }
            }

            return AlertDialog(
              title: const Text('Import from URL'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      hintText: 'Paste image URL...',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !importing,
                    autofocus: true,
                    onSubmitted: importing ? null : (_) => doImport(),
                  ),
                  if (importing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text('Downloading...', style: WTheme.bodySmall),
                  ],
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(error, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
              actions: [
                if (!importing)
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                if (!importing)
                  FilledButton(
                    onPressed: doImport,
                    child: const Text('Import'),
                  ),
              ],
            );
          },
        );
      },
    ).then((path) {
      if (path != null && mounted) {
        setState(() => _artPath = path as String?);
      }
    });
  }

  void _resetArt() {
    setState(() => _artPath = null);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cover art for "${widget.playlist.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: WTheme.surface,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.photo_library_rounded),
                        title: const Text('Choose from gallery'),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _pickFromGallery();
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.link_rounded),
                        title: const Text('Paste image URL'),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showUrlImportDialog();
                        },
                      ),
                      if (widget.playlist.coverArtPath != null)
                        ListTile(
                          leading: const Icon(Icons.restore_rounded),
                          title: const Text('Reset to default'),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _resetArt();
                          },
                        ),
                    ],
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: WTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _artPath != null
                    ? Image.file(
                        File(_artPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder,
                      )
                    : _placeholder,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (_artPath == widget.playlist.coverArtPath) {
              Navigator.of(context).pop();
              return;
            }
            await widget.onSave(_artPath);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget get _placeholder => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.queue_music_rounded, size: 48, color: WTheme.accent),
            const SizedBox(height: 4),
            Text('Tap to set cover', style: WTheme.bodySmall),
          ],
        ),
      );
}
