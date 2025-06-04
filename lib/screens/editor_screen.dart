import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shot.dart';
import '../providers/session_provider.dart';

class EditorScreen extends ConsumerWidget {
  final int index;
  const EditorScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shots = ref.watch(sessionProvider).value;
    final shot = shots?[index];

    if (shot == null || shot.original == null) {
      return const Scaffold(body: Center(child: Text('이미지 없음')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('필터 적용 - ${shot.index + 1}번째')),
      body: Column(
        children: [
          Expanded(child: Image.memory(shot.original!)),
          Wrap(
            spacing: 10,
            children: FilterType.values.map((f) {
              return ElevatedButton(
                onPressed: () {
                  final edited = shot.original; // TODO: 필터 실제 적용
                  ref
                      .read(sessionProvider.notifier)
                      .updateEditedShot(index, edited!, f);
                  Navigator.pop(context);
                },
                child: Text(f.name),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
