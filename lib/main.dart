import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/session_provider.dart'; // navigatorKey 얻기 위해 추가
import 'screens/lobby_screen.dart';

void main() {
  runApp(const ProviderScope(child: PhotogramApp()));
}

class PhotogramApp extends ConsumerWidget {
  // ← Stateless → ConsumerWidget
  const PhotogramApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SessionNotifier 가 보유한 navigatorKey
    final navKey = ref.read(sessionProvider.notifier).navigatorKey;

    return MaterialApp(
      title: 'Photogram',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navKey, // ✅ 꼭 전달!
      home: const LobbyScreen(),
    );
  }
}
