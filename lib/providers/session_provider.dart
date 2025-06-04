import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../models/shot.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../screens/result_screen.dart';
import 'dart:typed_data';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<List<Shot>>>((ref) {
      return SessionNotifier(ref);
    });

class SessionNotifier extends StateNotifier<AsyncValue<List<Shot>>> {
  SessionNotifier(this.ref) : super(const AsyncValue.loading());
  final Ref ref;
  Timer? timer;
  int secondsLeft = 60;
  final navigatorKey = GlobalKey<NavigatorState>();
  String uuid = 'mock-session-id'; // TODO: 서버에서 받아오도록 구현

  Future<void> startSession() async {
    final shots = List.generate(4, (i) => Shot(index: i));
    state = AsyncValue.data(shots);
    ref.read(socketServiceProvider).connect(onPhotoReceived);
    startCountdown();
  }

  void startCountdown() {
    timer?.cancel();
    secondsLeft = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (secondsLeft <= 0) {
        t.cancel();
        await confirmAll();
      } else {
        secondsLeft--;
        state = AsyncValue.data(state.value ?? []); // 상태 강제 갱신용
      }
    });
  }

  void onPhotoReceived(int index, Uint8List imageBytes) {
    state.whenData((shots) {
      final updated = [...shots];
      updated[index] = updated[index].copyWith(original: imageBytes);
      state = AsyncValue.data(updated);
    });
  }

  void updateEditedShot(int index, Uint8List editedBytes, FilterType filter) {
    state.whenData((shots) {
      final updated = [...shots];
      updated[index] = updated[index].copyWith(
        edited: editedBytes,
        filter: filter,
      );
      state = AsyncValue.data(updated);
    });
  }

  Future<void> confirmAll() async {
    await ref.read(apiServiceProvider).confirmSession(uuid);
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ResultScreen(url: 'https://example.com/qr123'),
      ),
    );
  }
}
