import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shot.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/editor_screen.dart';
import '../screens/result_screen.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<List<Shot>>>((ref) {
      return SessionNotifier(ref);
    });

class SessionNotifier extends StateNotifier<AsyncValue<List<Shot>>> {
  SessionNotifier(this.ref) : super(const AsyncValue.loading()) {
    // 소켓 연결과 콜백 등록
    ref.read(socketServiceProvider).connect(onPhotoReceived);
  }

  final Ref ref;
  static const int _maxShots = 4;
  static const int _perShotLimit = 10;

  int _currentIndex = 0;
  int secondsLeft = _perShotLimit;
  Timer? _timer;
  final navigatorKey = GlobalKey<NavigatorState>();
  final String uuid = 'mock-session-id';

  // ───────── 공개 래퍼 (CaptureScreen에서 호출)
  void startShotTimer() => _startPerShotTimer();
  void handleShotTimeout() => _handleTimeoutAndRequest();

  // ───────── 내부 타이머 관리
  void _startPerShotTimer() {
    _timer?.cancel();
    secondsLeft = _perShotLimit;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      secondsLeft--;
      state = AsyncValue.data(state.value ?? []);
      if (secondsLeft <= 0) {
        _handleTimeoutAndRequest();
      }
    });
  }

  void _handleTimeoutAndRequest() {
    _timer?.cancel();
    ref.read(socketServiceProvider).requestPhoto(_currentIndex);
    _startPerShotTimer();
  }

  // ───────── 사진 수신
  void onPhotoReceived(int idx, Uint8List bytes) {
    final list = [
      ...state.value ?? List.generate(_maxShots, (i) => Shot(index: i)),
    ];
    list[idx] = list[idx].copyWith(original: bytes);
    state = AsyncValue.data(list);

    _currentIndex = idx + 1;
    if (_currentIndex >= _maxShots) {
      _timer?.cancel();
      // 4번째 사진까지 모두 수신 완료
      print('4번째 사진까지 모두 수신 완료. 편집 화면으로 이동합니다.');
      // EditorScreen으로 이동
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(
          builder: (_) => const EditorScreen(), // EditorScreen으로 이동
        ),
      );
    }
  }

  // ───────── 편집 및 확인
  void updateEditedShot(int index, Uint8List edited, FilterType filter) {
    state.whenData((shots) {
      final updated = [...shots];
      updated[index] = updated[index].copyWith(edited: edited, filter: filter);
      state = AsyncValue.data(updated);
    });
  }

  Future<void> confirmSession() async {
    await ref.read(apiServiceProvider).confirmSession(uuid);
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ResultScreen(url: 'https://example.com/qr123'),
      ),
    );
  }

  // ───────── 세션 시작
  Future<bool> connectToServer() async {
    try {
      final socketService = ref.read(socketServiceProvider);
      // 소켓 서비스의 연결 상태 확인
      final isConnected = await socketService.isConnected();
      if (!isConnected) {
        // 연결이 되어있지 않다면 다시 연결 시도
        await socketService.connect(onPhotoReceived);
      }
      return true;
    } catch (e) {
      print('서버 연결 실패: $e');
      return false;
    }
  }

  Future<void> startSession() async {
    state = AsyncValue.data(List.generate(_maxShots, (i) => Shot(index: i)));
    _currentIndex = 0;
    _startPerShotTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    ref.read(socketServiceProvider).dispose();
    super.dispose();
  }
}
