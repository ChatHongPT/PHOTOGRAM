import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/lobby_screen.dart';
import 'screens/emoji_editor_screen.dart';
import 'screens/frame_selection_screen.dart';
import 'providers/session_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionNotifier = ref.read(sessionProvider.notifier);

    return MaterialApp(
      navigatorKey: sessionNotifier.navigatorKey,
      title: 'Photogram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LobbyScreen(),
        '/emoji_editor': (context) => const EmojiEditorScreen(shots: []),
        '/frame_selection': (context) => const FrameSelectionScreen(shots: [], addedEmojis: {}),
      },
    );
  }
}
