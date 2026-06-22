import 'package:flutter/material.dart';

import '../services/audio_handler.dart';
import '../services/file_picker_service.dart';
import '../services/player_state.dart';
import '../services/url_import_service.dart';
import '../theme/stitch_theme.dart';
import '../widgets/glass_player_bar.dart';
import 'home_screen.dart';
import 'player_screen.dart';
import 'playlists_screen.dart';

/// Root scaffold that hosts the library, the player, and the floating glass bar.
class AppShell extends StatefulWidget {
  final WAudioHandler audioHandler;
  final PlayerState playerState;
  final FilePickerService filePickerService;

  const AppShell({
    super.key,
    required this.audioHandler,
    required this.playerState,
    required this.filePickerService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _showPlayer = false;
  bool _showPlaylists = false;
  final _urlImportService = UrlImportService();

  Future<void> _pickFiles() async {
    final tracks = await widget.filePickerService.pickAudioFiles();
    if (tracks.isEmpty) return;
    // เพิ่มเข้าไลบรารีเดิม ไม่แทนที่ทั้งหมด เหมือนเพิ่มเพลงใหม่ลง Spotify
    await widget.playerState.addAllToQueue(tracks);
  }

  Future<void> _pickFolder() async {
    final tracks = await widget.filePickerService.pickAudioDirectory();
    if (tracks.isEmpty) return;
    // เพิ่มเพลงทั้งโฟลเดอร์เข้าไลบรารีเดิม ไม่แทนที่ทั้งหมด
    await widget.playerState.addAllToQueue(tracks);
  }

  Future<UrlImportResult> _pickUrl(String url) async {
    final result = await _urlImportService.importFromUrl(url);
    if (result.isSuccess) {
      await widget.playerState.addAllToQueue([result.track!]);
    }
    return result;
  }

  Future<void> _clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear library'),
        content: Text(
          'This will remove all ${widget.playerState.queue.value.length} songs. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.playerState.clearLibrary();
    }
  }

  void _openPlaylists() {
    setState(() => _showPlaylists = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WTheme.background,
      body: Stack(
        children: [
          if (_showPlaylists)
            PlaylistsScreen(
              playerState: widget.playerState,
              onOpenPlayer: () => setState(() => _showPlayer = true),
              onClose: () => setState(() => _showPlaylists = false),
            )
          else
            HomeScreen(
              playerState: widget.playerState,
              onPickFiles: _pickFiles,
              onPickFolder: _pickFolder,
              onPickUrl: _pickUrl,
              onOpenPlayer: () => setState(() => _showPlayer = true),
              onClearLibrary: _clearLibrary,
              onOpenPlaylists: _openPlaylists,
            ),
          if (_showPlayer)
            PlayerScreen(
              playerState: widget.playerState,
              onClose: () => setState(() => _showPlayer = false),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ValueListenableBuilder(
                valueListenable: widget.playerState.currentTrack,
                builder: (context, track, _) {
                  if (track == null) return const SizedBox.shrink();
                  return GlassPlayerBar(
                    playerState: widget.playerState,
                    onTap: () => setState(() => _showPlayer = true),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
