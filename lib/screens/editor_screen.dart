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
    FilterType.chrome => '비비드',
  };

  IconData get icon => switch (this) {
    FilterType.none => Icons.photo_outlined,
    FilterType.mono => Icons.monochrome_photos_rounded,
    FilterType.sepia => Icons.wb_sunny_rounded,
    FilterType.chrome => Icons.auto_awesome_rounded,
  };

  Color get color => switch (this) {
    FilterType.none => const Color(0xFF6366F1),
    FilterType.mono => const Color(0xFF64748B),
    FilterType.sepia => const Color(0xFFFB7185),
    FilterType.chrome => const Color(0xFF10B981),
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
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  int? _selectedImageIndex;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 10 && !_pulseController.isAnimating) {
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

  LinearGradient _getTimerGradient() {
    if (_secondsLeft <= 10) {
      return const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    if (_secondsLeft <= 20) {
      return const LinearGradient(
        colors: [Color(0xFFFFB347), Color(0xFFFFCC33)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shots = ref.watch(sessionProvider).value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPhotoGrid(shots)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0A0B),
            const Color(0xFF0A0A0B).withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _secondsLeft <= 10 ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _getTimerGradient(),
                    boxShadow: [
                      BoxShadow(
                        color: _getTimerGradient().colors.first.withOpacity(
                          0.4,
                        ),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                        width: 50,
                        height: 50,
                  child: CircularProgressIndicator(
                    value: _secondsLeft / _editLimit,
                    strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.3),
                  ),
                ),
                Text(
                  '$_secondsLeft',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '포토 에디터',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
            const Text(
              '편집',
              style: TextStyle(
                color: Colors.white,
                    fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _finishAndConfirm,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<Shot> shots) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        itemCount: shots.length,
      itemBuilder: (context, index) => _buildPhotoCard(shots[index], index),
    );
  }

  Widget _buildPhotoCard(Shot shot, int index) {
    final isSelected = _selectedImageIndex == index;

    return GestureDetector(
      onTap: () => _showFilterSelector(shot, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(isSelected ? 1.05 : 1.0)
          ..rotateZ(isSelected ? 0.01 : 0.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1A1A1B), const Color(0xFF2D2D30)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: isSelected ? 25 : 15,
                spreadRadius: isSelected ? 2 : 0,
                offset: Offset(0, isSelected ? 10 : 5),
              ),
              if (isSelected)
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
            ],
          ),
          child: Column(
            children: [
              Expanded(flex: 5, child: _buildPhotoImage(shot, index)),
              Expanded(flex: 2, child: _buildFilterSection(shot, index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoImage(Shot shot, int index) {
    return Container(
      margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
            if (shot.edited != null)
              Image.memory(shot.edited!, fit: BoxFit.cover)
            else if (shot.original != null)
              Image.memory(shot.original!, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[700]!],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),

            // 필터 표시
            if (shot.filter != null && shot.filter != FilterType.none)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                              ),
                              decoration: BoxDecoration(
                    color: shot.filter!.color,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: shot.filter!.color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(shot.filter!.icon, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        shot.filter!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 탭 오버레이
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(Shot shot, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: shot.filter?.color ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                              child: Text(
                  shot.filter?.label ?? '필터 없음',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                ),
              ),
              Icon(
                Icons.touch_app_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  shot.filter?.color.withOpacity(0.3) ??
                      Colors.grey.withOpacity(0.3),
                  shot.filter?.color ?? Colors.grey,
                ],
                              ),
                            ),
                          ),
                      ],
      ),
    );
  }

  void _showFilterSelector(Shot shot, int index) {
    setState(() {
      _selectedImageIndex = index;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A1B), Color(0xFF0A0A0B)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            // 핸들
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 헤더
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '필터 선택',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '원하는 스타일을 선택해보세요',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 필터 그리드
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
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
                      setState(() => _selectedImageIndex = null);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  filter.color,
                                  filter.color.withOpacity(0.7),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFF2D2D30),
                                  const Color(0xFF1A1A1B),
                                ],
                              ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: filter.color.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            filter.icon,
                            size: 28,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ).then((_) {
      setState(() => _selectedImageIndex = null);
    });
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
    _fadeController.dispose();
    super.dispose();
  }
}
