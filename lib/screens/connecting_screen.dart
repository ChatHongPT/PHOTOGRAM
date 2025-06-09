// lib/screens/connecting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import 'capture_screen.dart';
import 'dart:async';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  String? error;
  bool _isConnected = false;
  int _preparationSeconds = 10;
  Timer? _preparationTimer;

  @override
  void initState() {
    super.initState();
    _attemptConnection();
  }

  @override
  void dispose() {
    _preparationTimer?.cancel();
    super.dispose();
  }

  Future<void> _attemptConnection() async {
    final ok = await ref.read(sessionProvider.notifier).connectToServer();
    if (!mounted) return;

    if (ok) {
      setState(() {
        _isConnected = true;
      });
      _startPreparationTimer();
    } else {
      setState(() => error = '임베디드 서버와 연결에 실패했습니다.');
    }
  }

  void _startPreparationTimer() {
    _preparationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_preparationSeconds > 0) {
          _preparationSeconds--;
        } else {
          _preparationTimer?.cancel();
          _startCaptureSession();
        }
      });
    });
  }

  void _startCaptureSession() async {
    await ref.read(sessionProvider.notifier).startSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CaptureScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: error == null
            ? _isConnected
                ? _buildPreparationScreen()
                : _buildConnectingScreen()
            : _buildErrorScreen(),
      ),
    );
  }

  Widget _buildConnectingScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          '임베디드 서버에 연결 중...',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPreparationScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.1),
            border: Border.all(
              color: Colors.blue,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              '$_preparationSeconds',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '촬영 준비 중...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '곧 촬영이 시작됩니다',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Column(
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
    );
  }
}
