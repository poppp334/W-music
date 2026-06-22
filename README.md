# W Music

**"A local-first, offline music player for people who just want to listen without the noise."**

- The "CD Wallet" era, but digital: You own the files. You organize them the way you want. You don't need a signal bar to prove you have the right to listen.

- Phone in pocket, music on: Background playback + lockscreen controls mean you nailed the core physical interaction. Close the phone, hit play, go about your day—zero friction.

- Privacy by default: No analytics, no login, no data harvesting. It's just a media player that respects the device it's running on.

W Music is a free, open-source Flutter music player that plays audio files stored on your device — no subscriptions, no ads, no internet required.

While services like YouTube Music, Spotify, and Apple Music lock offline playback behind paid subscriptions, W Music gives you the same core feature for free. Import your local music files, organize them into playlists, and listen with your phone in airplane mode.

## Comparison

| Feature | W Music | YouTube Music | Spotify | Apple Music |
|---|---|---|---|---|
| **Price** | Free | Free w/ ads or $10.99/mo | Free w/ ads or $10.99/mo | $10.99/mo |
| **Play local files** | ✅ Yes | ❌ No | ❌ No | ❌ No |
| **Offline playback** | ✅ Included | 🔒 Premium only | 🔒 Premium only | 🔒 Included (paid) |
| **Unlimited skips** | ✅ Yes | 🔒 Premium only | 🔒 Premium only | ✅ Yes |
| **No ads** | ✅ Yes | 🔒 Premium only | 🔒 Premium only | ✅ Yes |
| **Playlists** | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| **Open source** | ✅ MIT | ❌ | ❌ | ❌ |

## Features

- Play local audio files (MP3, FLAC, WAV, AAC, etc.)
- Import entire folders or individual tracks
- Create and manage playlists
- Persistent queue across sessions
- Album art extraction and display
- Glassmorphism UI with dark theme
- Background playback with notification controls

## Getting Started

```bash
git clone git@github.com:poppp334/W-music.git
cd W-music
flutter pub get
flutter run
```

Requires Flutter SDK. Tested on Android.
