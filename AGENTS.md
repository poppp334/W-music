# W Music — AGENTS.md

## Tech

Flutter/Dart, `just_audio` + `audio_service` for playback, `file_picker` for imports, `shared_preferences` for persistence, `audio_metadata_reader` for album art, `rxdart` for streams.

Accent color: `#B8A4F5` (lavender) — ignore `DESIGN.md` which describes a `#1DB954` green theme that was never implemented.

## Commands

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter run` | Run on device/emulator |
| `flutter test` | Run tests |
| `flutter analyze` | Lint / static analysis |

## Architecture

```
main.dart → WApp → AppShell
  ├── HomeScreen (library, list/grid toggle, import, track edit)
  ├── PlayerScreen (full-screen with blurred art backdrop)
  ├── PlaylistsScreen (list/grid, detail view with track list)
  └── GlassPlayerBar (persistent floating mini-player)
```

- `main.dart` — inits `AudioService` + `PlayerState` + `FilePickerService`
- `services/audio_handler.dart` — `WAudioHandler` wraps `AudioPlayer`
- `services/player_state.dart` — reactive state via `ValueNotifier`s (no Riverpod/Bloc/Provider)
- `services/file_picker_service.dart` — picks files/folders, returns `List<Track>`
- `services/url_import_service.dart` — downloads audio from HTTP(S) URL
- `services/image_import_service.dart` — picks/downloads cover art for custom metadata
- `models/track.dart` — `Track` data class with `fromFileWithArt()` for album art extraction
- `models/playlist.dart` — `Playlist` model with JSON serialization for persistence
- `theme/stitch_theme.dart` — "Sonic Dark" design system, Inter font
- `widgets/glass_container.dart` — shared `BackdropFilter` glassmorphism container
- `widgets/glass_player_bar.dart` — floating mini-player with progress line

## State & queue

- **Two queues:** `queue` (permanent library, persisted to `SharedPreferences`) and `nowPlayingQueue` (what the audio handler currently has loaded)
- `addAllToQueue()` appends without replacing (Spotify-style). `setQueue()` replaces. `loadQueueSilently()` restores on startup without auto-playing.
- `playTracks()` (used by playlist playback) sets `_libraryLoadedInHandler = false`; `playTrackAtIndex()` reloads the handler when this flag is false.
- `resolvePlaylistTracks()` matches stored file paths against the library queue to resolve `Playlist` → `List<Track>`.
- `cycleRepeatMode()` cycles off → one → all.
- Subscribe with `ValueListenableBuilder`. State held in `ValueNotifier`s on `PlayerState`.

## Testing

Tests avoid `audio_service`/`just_audio` so they run in plain `flutter test`. They cover `Track`, `PlayerState` data classes (`WRepeatMode`, `PositionData`), and `WTheme`. Adding audio playback tests requires mocking.

## Album art

Extracted at import time via `Track.fromFileWithArt()` in `file_picker_service.dart`. Cached to `getApplicationDocumentsDirectory()` with hash-based filenames. Cached art is cleaned up on track removal and library clear (`_deleteArtFile`). All display widgets have `errorBuilder` fallbacks. `loadQueueSilently()` does not re-extract art — restored tracks have `null` `albumArtPath` until re-imported (falls back to music-note icon).

## Conventions

- **Imports:** relative within `lib/`
- **Design tokens:** Use `WTheme.*` constants — don't hardcode colors/spacing
- **Android permissions:** Android 13+ uses `Permission.audio`; older uses `Permission.storage` (handled in `FilePickerService`)
- **Android notification channel:** `com.wmusic.audio`

## Not part of the app

- `fix_android_*.sh` scripts — local SDK/NDK workarounds
- `aienv/` directory — AI tool environment setup
- `DESIGN.md` — describes Spotify-green theme that was never implemented; the code uses lavender (`#B8A4F5`)
