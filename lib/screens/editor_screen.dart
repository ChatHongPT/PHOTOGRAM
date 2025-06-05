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

  IconData get icon => switch (this) {
    FilterType.none => Icons.photo,
    FilterType.mono => Icons.filter_b_and_w,
    FilterType.sepia => Icons.filter_vintage,
    FilterType.chrome => Icons.auto_fix_high,
  };
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorState();
}

class _EditorState extends ConsumerState<EditorScreen>
    with TickerProviderStateMixin {
  static const int _editLimit = 60;
  late int _secondsLeft = _editLimit;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _selectedImageIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10) {
        _pulseController.repeat(reverse: true);
      }
      if (_secondsLeft == 0) {
        _finishAndConfirm();
      }
    });
  }

  void _finishAndConfirm() {
    _timer?.cancel();
    _pulseController.stop();
    ref.read(sessionProvider.notifier).confirmSession();
  }

  Color _getTimerColor() {
    if (_secondsLeft <= 10) return Colors.red;
    if (_secondsLeft <= 20) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final shots = ref.watch(sessionProvider).value ?? [];
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _buildPhotoGrid(shots),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _secondsLeft <= 10 ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getTimerColor().withOpacity(0.1),
                      border: Border.all(color: _getTimerColor(), width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: _secondsLeft / _editLimit,
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTimerColor(),
                            ),
                            backgroundColor: _getTimerColor().withOpacity(0.2),
                          ),
                        ),
                        Text(
                          '$_secondsLeft',
                          style: TextStyle(
                            color: _getTimerColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '편집',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '사진을 탭해서 필터를 적용하세요',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          child: ElevatedButton.icon(
            onPressed: _finishAndConfirm,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(List<Shot> shots) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildPhotoCard(shots[index], index),
        childCount: shots.length,
      ),
    );
  }

  Widget _buildPhotoCard(Shot shot, int index) {
    final isSelected = _selectedImageIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: _buildPhotoImage(shot, index)),
            Expanded(flex: 1, child: _buildFilterChips(shot, index)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoImage(Shot shot, int index) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (shot.edited != null)
              Image.memory(shot.edited!, fit: BoxFit.cover)
            else if (shot.original != null)
              Image.memory(shot.original!, fit: BoxFit.cover)
            else
              Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),

            // 필터 라벨
            if (shot.filter != null && shot.filter != FilterType.none)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(shot.filter!.icon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        shot.filter!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 탭 영역
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedImageIndex = _selectedImageIndex == index
                          ? null
                          : index;
                    });
                    _showFilterBottomSheet(context, shot, index);
                  },
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      color: _selectedImageIndex == index
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(Shot shot, int index) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: FilterType.values
            .where((f) => f != FilterType.none)
            .map((filter) => _buildFilterChip(shot, filter, index))
            .toList(),
      ),
    );
  }

  Widget _buildFilterChip(Shot shot, FilterType filter, int index) {
    final isSelected = shot.filter == filter;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        onSelected: shot.original == null
            ? null
            : (selected) {
                if (selected) {
                  final filtered = _applyFilter(shot.original!, filter);
                  ref
                      .read(sessionProvider.notifier)
                      .updateEditedShot(index, filtered, filter);
                }
              },
        label: Text(
          filter.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
        avatar: Icon(
          filter.icon,
          size: 12,
          color: isSelected ? Colors.white : Colors.grey[600],
        ),
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey[100],
        checkmarkColor: Colors.white,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, Shot shot, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '필터 선택',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: FilterType.values.length,
              itemBuilder: (context, i) {
                final filter = FilterType.values[i];
                final isSelected = shot.filter == filter;

                return GestureDetector(
                  onTap: () {
                    if (shot.original != null) {
                      final editedBytes = filter == FilterType.none
                          ? shot.original!
                          : _applyFilter(shot.original!, filter);
                      ref
                          .read(sessionProvider.notifier)
                          .updateEditedShot(index, editedBytes, filter);
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filter.icon,
                          size: 32,
                          color: isSelected ? Colors.blue : Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filter.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? Colors.blue : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
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
    _pulseController.dispose();
    super.dispose();
  }
}
