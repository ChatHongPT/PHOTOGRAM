// lib/screens/connecting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import 'capture_screen.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  String? error;

  @override
  void initState() {
    super.initState();
    _attemptConnection();
  }

  Future<void> _attemptConnection() async {
    final ok = await ref.read(sessionProvider.notifier).connectToServer();
    if (!mounted) return;

    if (ok) {
      await ref.read(sessionProvider.notifier).startSession();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CaptureScreen()),
      );
    } else {
      setState(() => error = '임베디드 서버와 연결에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: error == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '임베디드 서버에 연결 중...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _attemptConnection,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
      ),
    );
  }
}
