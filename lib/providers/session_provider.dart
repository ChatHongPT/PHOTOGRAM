import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shot.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<List<Shot>>>((ref) {
      return SessionNotifier(ref);
    });

class SessionNotifier extends StateNotifier<AsyncValue<List<Shot>>> {
  SessionNotifier(this.ref) : super(const AsyncValue.loading());
  final Ref ref;
  Timer? timer;
  int secondsLeft = 60;

  Future<void> startSession() async {
    final shots = List.generate(4, (i) => Shot(index: i));
    state = AsyncValue.data(shots);
    ref.read(socketServiceProvider).connect(onPhotoReceived);
    startCountdown();
  }

  void startCountdown() {
    timer?.cancel();
    secondsLeft = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 0) {
        t.cancel();
      } else {
        secondsLeft--;
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
}
