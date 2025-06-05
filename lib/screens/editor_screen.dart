import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../models/shot.dart';
import '../providers/session_provider.dart';

extension FilterLabel on FilterType {
  String get label => switch (this) {
    FilterType.none => '원본',
    FilterType.mono => '흑백',
    FilterType.sepia => '세피아',
    FilterType.chrome => '크롬',
  };
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<EditorScreen> {
  static const int _editLimit = 60; // 60초 편집 시간
  late int _secondsLeft = _editLimit;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft == 0) {
        _finishAndConfirm();
      }
    });
  }

  void _finishAndConfirm() {
    _timer?.cancel();
    ref.read(sessionProvider.notifier).confirmAll();
  }

  @override
  Widget build(BuildContext context) {
    final shots = ref.watch(sessionProvider).value ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / _editLimit,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    backgroundColor: Colors.white24,
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            const Text(
              '편집',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_circle,
              size: 28,
              color: Colors.orange,
            ),
            onPressed: _finishAndConfirm,
            tooltip: '완료',
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 0.8,
        ),
        itemCount: shots.length,
        itemBuilder: (context, i) {
          final s = shots[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (s.edited != null)
                          Image.memory(s.edited!, fit: BoxFit.cover)
                        else if (s.original != null)
                          Image.memory(s.original!, fit: BoxFit.cover)
                        else
                          const Center(child: CircularProgressIndicator()),
                        if (s.filter != null && s.filter != FilterType.none)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.filter!.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: FilterType.values
                    .where((f) => f != FilterType.none)
                    .map(
                      (f) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.filter == f
                              ? Colors.orange
                              : Colors.white,
                          foregroundColor: s.filter == f
                              ? Colors.white
                              : Colors.black87,
                          elevation: 0,
                          minimumSize: const Size(48, 32),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: s.filter == f
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onPressed: s.original == null
                            ? null
                            : () {
                                final filtered = _applyFilter(s.original!, f);
                                ref
                                    .read(sessionProvider.notifier)
                                    .updateEditedShot(i, filtered, f);
                              },
                        child: Text(
                          f.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Uint8List _applyFilter(Uint8List bytes, FilterType filter) {
    final src = img.decodeImage(bytes)!;
    final img.Image dst = switch (filter) {
      FilterType.mono => img.grayscale(src),
      FilterType.sepia => img.sepia(src),
      FilterType.chrome => img.adjustColor(src, saturation: 1.5),
      _ => src,
    };
    return Uint8List.fromList(img.encodeJpg(dst));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
