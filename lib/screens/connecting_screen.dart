// screens/connecting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import 'capture_screen.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingState();
}

class _ConnectingState extends ConsumerState<ConnectingScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _tryConnect();
  }

  Future<void> _tryConnect() async {
    setState(() => _error = null);
    final ok = await ref.read(sessionProvider.notifier).connectToServer();
    if (ok && mounted) {
      // 연결 성공 → 촬영 세션으로
      ref.read(sessionProvider.notifier).startSession();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaptureScreen()),
      );
    } else if (mounted) {
      setState(() => _error = '임베디드와 연결할 수 없습니다');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: _error == null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('임베디드와 통신 중...', style: TextStyle(color: Colors.white70)),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _tryConnect,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
    ),
  );
}
