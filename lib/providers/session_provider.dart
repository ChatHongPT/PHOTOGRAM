import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/shot.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/editor_screen.dart' show EditorScreen; // ✅ EditorScreen만
import '../screens/result_screen.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<List<Shot>>>(
      (ref) => SessionNotifier(ref),
    );

class SessionNotifier extends StateNotifier<AsyncValue<List<Shot>>> {
  SessionNotifier(this.ref) : super(const AsyncValue.loading());

  // deps
  final Ref ref;
  final navigatorKey = GlobalKey<NavigatorState>();

  // constants
  static const int _maxShots = 4;
  static const int _perShotLimit = 10;

  // state
  int _currentIndex = 0;
  int secondsLeft = _perShotLimit;

  // timer
  Timer? _tickTimer;

  // mock session id
  final String uuid = 'mock-session-id';

  // ───────────────────────────────────────────────────────── start session
  Future<void> startSession() async {
    state = AsyncValue.data(List.generate(_maxShots, (i) => Shot(index: i)));
    ref.read(socketServiceProvider).connect(onPhotoReceived);
    _startPerShotTimer();
  }

  // ───────────────────────────────────────────────────────── per-shot timer
  void _startPerShotTimer() {
    _tickTimer?.cancel();
    secondsLeft = _perShotLimit;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      secondsLeft--;
      state = AsyncValue.data(state.value ?? []);

      if (secondsLeft <= 0) {
        timer.cancel();
        // 4장이 이미 다 들어왔는지 실제 카운트로 판단
        final captured =
            state.value?.where((s) => s.original != null).length ?? 0;
        if (captured == _maxShots) {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
        }
        _requestPhoto();
      }
    });
  }

  void _requestPhoto() {
    if (_currentIndex >= _maxShots) return;
    ref.read(socketServiceProvider).requestPhoto(_currentIndex);
  }

  // ───────────────────────────────────────────────────────── receive photo
  void onPhotoReceived(int index, Uint8List bytes) {
    state.whenData((shots) {
      final updated = [...shots];
      updated[index] = updated[index].copyWith(original: bytes);
      state = AsyncValue.data(updated);
    });

    _currentIndex++;
    // 1~3번째 컷이면 다음 10초 타이머 재시작
    if (_currentIndex < _maxShots) _startPerShotTimer();
  }

  // ───────────────────────────────────────────────────────── store edits
  void updateEditedShot(int index, Uint8List edited, FilterType filter) {
    state.whenData((shots) {
      final updated = [...shots];
      updated[index] = updated[index].copyWith(edited: edited, filter: filter);
      state = AsyncValue.data(updated);
    });
  }

  // ───────────────────────────────────────────────────────── confirm
  Future<void> confirmAll() async {
    await ref.read(apiServiceProvider).confirmSession(uuid);
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ResultScreen(url: 'https://example.com/qr123'),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
