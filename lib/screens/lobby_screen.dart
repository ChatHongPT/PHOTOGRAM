import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import 'capture_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(sessionProvider.notifier).startSession();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CaptureScreen()),
            );
          },
          child: const Text('📸 사진 촬영 시작'),
        ),
      ),
    );
  }
}
