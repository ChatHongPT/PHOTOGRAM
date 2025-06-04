import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/lobby_screen.dart';

void main() {
  runApp(const ProviderScope(child: PhotogramApp()));
}

class PhotogramApp extends StatelessWidget {
  const PhotogramApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photogram',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const LobbyScreen(),
    );
  }
}
