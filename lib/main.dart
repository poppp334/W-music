import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'services/audio_handler.dart';
import 'services/file_picker_service.dart';
import 'services/player_state.dart';
import 'theme/stitch_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: WTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final audioHandler = await AudioService.init<WAudioHandler>(
    builder: WAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.wmusic.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  final playerState = PlayerState(audioHandler);
  await playerState.init();
  final filePickerService = FilePickerService();

  runApp(WApp(
    audioHandler: audioHandler,
    playerState: playerState,
    filePickerService: filePickerService,
  ));
}

class WApp extends StatelessWidget {
  final WAudioHandler audioHandler;
  final PlayerState playerState;
  final FilePickerService filePickerService;

  const WApp({
    super.key,
    required this.audioHandler,
    required this.playerState,
    required this.filePickerService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'W Music',
      debugShowCheckedModeBanner: false,
      theme: WTheme.darkTheme,
      home: AppShell(
        audioHandler: audioHandler,
        playerState: playerState,
        filePickerService: filePickerService,
      ),
    );
  }
}