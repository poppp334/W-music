import 'dart:io';

import 'package:flutter/material.dart';

import '../models/track.dart';
import '../services/image_import_service.dart';
import '../services/player_state.dart';
import '../services/url_import_service.dart';
import '../theme/stitch_theme.dart';
import '../widgets/glass_container.dart';

/// Home screen with the "Sonic Dark" library view.
class HomeScreen extends StatelessWidget {
  final PlayerState playerState;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final Future<UrlImportResult> Function(String url) onPickUrl;
  final VoidCallback onOpenPlayer;
  final VoidCallback onClearLibrary;
  final VoidCallback onOpenPlaylists;

  const HomeScreen({
    super.key,
    required this.playerState,
    required this.onPickFiles,
    required this.onPickFolder,
    required this.onPickUrl,
    required this.onOpenPlayer,
    required this.onClearLibrary,
    required this.onOpenPlaylists,
  });

  void _showAddToPlaylistPicker(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final playlists = playerState.playlists.value;

            Future<void> addAndClose(String playlistId) async {
              await playerState.addToPlaylist(playlistId, track);
              if (ctx.mounted) Navigator.of(ctx).pop();
            }

            Future<void> createNewAndClose() async {
              Navigator.of(ctx).pop();
              final nameController = TextEditingController();
              final name = await showDialog<String>(
                context: context,
                builder: (ctx2) {
                  var creating = false;
                  return StatefulBuilder(
                    builder: (ctx2, setInner) {
                      Future<void> doCreate() async {
                        final n = nameController.text.trim();
                        if (n.isEmpty || creating) return;
                        creating = true;
                        setInner(() {});
                        await playerState.createPlaylist(n);
                        if (ctx2.mounted) Navigator.of(ctx2).pop(n);
                      }

                      return AlertDialog(
                        title: const Text('New Playlist'),
                        content: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: 'Playlist name...',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                          onSubmitted:
                              creating ? null : (_) => doCreate(),
                        ),
                        actions: [
                          if (!creating)
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx2).pop(),
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
              if (name != null && context.mounted) {
                final created = playerState.playlists.value
                    .lastWhere((p) => p.name == name);
                await playerState.addToPlaylist(created.id, track);
              }
            }

            final items = <Widget>[
              ...playlists.map(
                (p) => ListTile(
                  leading: const Icon(
                    Icons.queue_music_rounded,
                    color: WTheme.accent,
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.trackPaths.length} ${p.trackPaths.length == 1 ? 'track' : 'tracks'}',
                    style: WTheme.bodySmall,
                  ),
                  onTap: () => addAndClose(p.id),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.add_rounded,
                  color: WTheme.accent,
                ),
                title: const Text('Create new'),
                onTap: () => createNewAndClose(),
              ),
            ];

            return AlertDialog(
              title: const Text('Add to playlist'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: items,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTrackEditDialog(BuildContext context, Track track) {
    showDialog(
      context: context,
      builder: (ctx) => _TrackEditDialog(
        track: track,
        onSave: (newTitle, newArtist, newArtPath) async {
          await playerState.setTrackCustomTitle(track.filePath, newTitle);
          await playerState.setTrackCustomArtist(track.filePath, newArtist);
          await playerState.setTrackCustomArt(track.filePath, newArtPath);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WTheme.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<Track>>(
          valueListenable: playerState.queue,
          builder: (context, tracks, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: playerState.isGridView,
              builder: (context, isGrid, _) {
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _Header(
                        trackCount: tracks.length,
                        isGridView: isGrid,
                        onToggleView: () =>
                            playerState.setGridView(!isGrid),
                        onPickFiles: onPickFiles,
                        onPickFolder: onPickFolder,
                        onPickUrl: onPickUrl,
                        onClearLibrary: onClearLibrary,
                        onOpenPlaylists: onOpenPlaylists,
                      ),
                    ),
                    if (tracks.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onPickFiles: onPickFiles, onPickFolder: onPickFolder),
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
                              final track = tracks[index];
                              return _TrackGridCard(
                                track: track,
                                isCurrent: playerState.currentTrack.value?.filePath ==
                                    track.filePath,
                                onTap: () async {
                                  await playerState.playTrackAtIndex(index);
                                  onOpenPlayer();
                                },
                              );
                            },
                            childCount: tracks.length,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: WTheme.gutter,
                        ),
                        sliver: SliverList.separated(
                          itemCount: tracks.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            return _TrackTile(
                              track: track,
                              index: index,
                              isCurrent: playerState.currentTrack.value?.filePath == track.filePath,
                              onTap: () async {
                                await playerState.playTrackAtIndex(index);
                                onOpenPlayer();
                              },
                              onRemove: () => playerState.removeTrack(index),
                              onAddToPlaylist: () =>
                                  _showAddToPlaylistPicker(
                                context,
                                track,
                              ),
                              onEdit: () =>
                                  _showTrackEditDialog(context, track),
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
  final int trackCount;
  final bool isGridView;
  final VoidCallback onToggleView;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final Future<UrlImportResult> Function(String url) onPickUrl;
  final VoidCallback onClearLibrary;
  final VoidCallback onOpenPlaylists;

  const _Header({
    required this.trackCount,
    required this.isGridView,
    required this.onToggleView,
    required this.onPickFiles,
    required this.onPickFolder,
    required this.onPickUrl,
    required this.onClearLibrary,
    required this.onOpenPlaylists,
  });

  void _showUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var importing = false;
        var error = '';
        return StatefulBuilder(
          builder: (ctx, setState) {
            Future<void> doImport() async {
              final url = controller.text.trim();
              if (url.isEmpty || importing) return;
              importing = true;
              setState(() {
                error = '';
              });
              final result = await onPickUrl(url);
              if (!ctx.mounted) return;
              if (result.isSuccess) {
                Navigator.of(ctx).pop();
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
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Paste a direct audio URL...',
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WTheme.gutter,
        WTheme.gutter,
        WTheme.gutter,
        WTheme.sectionMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Your Library', style: WTheme.displayMedium),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trackCount > 0)
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
                  PopupMenuButton<void>(
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Add music',
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: onPickFiles,
                        child: const Row(
                          children: [
                            Icon(Icons.audio_file_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Add files'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onPickFolder,
                        child: const Row(
                          children: [
                            Icon(Icons.folder_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Add folder'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => _showUrlDialog(context),
                        child: const Row(
                          children: [
                            Icon(Icons.link_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Add from URL'),
                          ],
                        ),
                      ),
                      if (trackCount > 0) ...[
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Clear library'),
                                content: Text(
                                  'This will remove all $trackCount songs. Are you sure?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      onClearLibrary();
                                    },
                                    child: const Text('Clear'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.delete_rounded, size: 20),
                              SizedBox(width: 12),
                              Text('Clear library'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _PillChip(label: 'All', selected: true),
              _PillChip(label: 'Playlists', onTap: onOpenPlaylists),
              _PillChip(label: 'Artists'),
              _PillChip(label: 'Albums'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pill Chip ───

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _PillChip({required this.label, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? WTheme.accent : WTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(WTheme.chipRadius),
      ),
      child: Text(
        label,
        style: WTheme.labelLarge.copyWith(
          color: selected ? Colors.black : WTheme.onSurface,
        ),
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WTheme.chipRadius),
      child: child,
    );
  }
}

// ─── Track Tile (List) ───

class _TrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onAddToPlaylist;
  final VoidCallback? onEdit;

  const _TrackTile({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.onTap,
    required this.onRemove,
    this.onAddToPlaylist,
    this.onEdit,
  });

  Widget _artWidget({double size = 48}) {
    final artPath = track.displayArtPath;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: artPath != null
            ? Image.file(
                File(artPath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackIcon,
              )
            : _fallbackIcon,
      ),
    );
  }

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
      color: isCurrent ? WTheme.glassSurfaceStrong : WTheme.glassSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _artWidget(),
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
                  if (onEdit != null)
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  if (onAddToPlaylist != null)
                    PopupMenuItem(
                      onTap: onAddToPlaylist,
                      child: const Row(
                        children: [
                          Icon(Icons.playlist_add_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Add to playlist'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    onTap: onRemove,
                    child: const Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Remove from library'),
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

// ─── Track Grid Card ───

class _TrackGridCard extends StatelessWidget {
  final Track track;
  final bool isCurrent;
  final VoidCallback onTap;

  const _TrackGridCard({
    required this.track,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      blur: 6,
      radius: WTheme.cardRadius,
      color: isCurrent ? WTheme.glassSurfaceStrong : WTheme.glassSurface,
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
                track.displayTitle,
                style: WTheme.titleSmall.copyWith(
                  color: isCurrent ? WTheme.accent : WTheme.onBackground,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                track.artist,
                style: WTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _artWidget() {
    final artPath = track.displayArtPath;
    if (artPath != null) {
      return Image.file(
        File(artPath),
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
        child: Center(
          child: Icon(
            isCurrent ? Icons.equalizer_rounded : Icons.music_note_rounded,
            color: WTheme.onSurfaceVariant,
            size: 32,
          ),
        ),
      );
}

// ─── Track Edit Dialog ───

class _TrackEditDialog extends StatefulWidget {
  final Track track;
  final Future<void> Function(String? title, String? artist, String? artPath) onSave;

  const _TrackEditDialog({
    required this.track,
    required this.onSave,
  });

  @override
  State<_TrackEditDialog> createState() => _TrackEditDialogState();
}

class _TrackEditDialogState extends State<_TrackEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  String? _artPath;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.displayTitle);
    _artistController = TextEditingController(text: widget.track.displayArtist);
    _artPath = widget.track.customArtPath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
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
      title: Text('Edit "${widget.track.displayTitle}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: WTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Custom title (leave empty to reset)',
                border: OutlineInputBorder(),
              ),
              autofocus: false,
            ),
            const SizedBox(height: 16),
            Text('Artist', style: WTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(
                hintText: 'Custom artist (leave empty to reset)',
                border: OutlineInputBorder(),
              ),
              autofocus: false,
            ),
            const SizedBox(height: 20),
            Text('Cover Art', style: WTheme.labelLarge),
            const SizedBox(height: 8),
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
                        if (widget.track.customArtPath != null)
                          ListTile(
                            leading: const Icon(Icons.restore_rounded),
                            title: const Text('Reset to original'),
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
                height: 160,
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
                          errorBuilder: (_, _, _) => _artPlaceholder,
                        )
                      : _artPlaceholder,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final title = _titleController.text;
            final artist = _artistController.text;
            final hasChanges = title != widget.track.displayTitle ||
                artist != widget.track.displayArtist ||
                _artPath != widget.track.customArtPath;
            if (!hasChanges) {
              Navigator.of(context).pop();
              return;
            }
            await widget.onSave(title, artist, _artPath);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget get _artPlaceholder => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.music_note_rounded, size: 48, color: WTheme.accent),
            const SizedBox(height: 4),
            Text('Tap to change', style: WTheme.bodySmall),
          ],
        ),
      );
}

// ─── Empty State ───

class _EmptyState extends StatelessWidget {
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  const _EmptyState({required this.onPickFiles, required this.onPickFolder});

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
                Icons.library_music_rounded,
                color: WTheme.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: WTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add music files from your device to start listening.',
              style: WTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onPickFiles,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Music'),
              style: FilledButton.styleFrom(
                backgroundColor: WTheme.accent,
                foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WTheme.buttonRadius),
                  ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onPickFolder,
              icon: const Icon(Icons.folder_rounded),
              label: const Text('Add Folder'),
              style: OutlinedButton.styleFrom(
                foregroundColor: WTheme.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(WTheme.buttonRadius),
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
