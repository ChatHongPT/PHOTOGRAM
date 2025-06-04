import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';
import '../widgets/countdown_timer.dart';

class CaptureScreen extends ConsumerWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shots = ref.watch(sessionProvider);
    final secondsLeft = ref.read(sessionProvider.notifier).secondsLeft;

    return Scaffold(
      appBar: AppBar(title: const Text('촬영 중...')),
      body: Column(
        children: [
          CountdownTimer(seconds: secondsLeft),
          Expanded(
            child: shots.when(
              data: (list) => GridView.count(
                crossAxisCount: 2,
                children: [
                  for (final shot in list)
                    Container(
                      margin: const EdgeInsets.all(8),
                      color: Colors.grey[800],
                      child: shot.original != null
                          ? Image.memory(shot.original!, fit: BoxFit.cover)
                          : const Center(child: Text('대기 중')),
                    ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('오류: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
