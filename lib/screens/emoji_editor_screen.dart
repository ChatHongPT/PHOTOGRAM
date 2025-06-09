import 'package:flutter/material.dart';
import '../models/shot.dart';
import 'dart:async'; // 타이머 사용을 위해 임포트 (이모지 편집 화면 타이머)
import 'frame_selection_screen.dart'; // 프레임 선택 화면으로 이동하기 위해 임포트

class EmojiEditorScreen extends StatefulWidget {
  final List<Shot> shots; // Shot 리스트를 받을 필드

  const EmojiEditorScreen({Key? key, required this.shots}) : super(key: key);

  @override
  State<EmojiEditorScreen> createState() => _EmojiEditorScreenState();
}

class _EmojiEditorScreenState extends State<EmojiEditorScreen> {
  int _currentIndex = 0; // 현재 편집 중인 사진 인덱스
  // TODO: 이모티콘 데이터 및 위치, 크기 등을 저장할 상태 변수 추가 필요

  // 사진 인덱스별 추가된 이모티콘 목록을 저장
  // 각 이모티콘은 { 'emoji': String, 'position': Offset, 'size': double, 'rotation': double } 형태로 저장 (rotation은 라디안)
  final Map<int, List<Map<String, dynamic>>> _addedEmojis = {};

  // 테스트용 기본 이모티콘 목록
  final List<String> _availableEmojis = ['😍', '👍', '✨', '😂', '👍', '🎉', '❤️', '🤩'];

  // 현재 사진에 배치하기 위해 선택된 이모티콘
  String? _selectedEmojiToPlace;

  // 현재 편집 중인 이모티콘의 리스트 내 인덱스 (없으면 null)
  int? _activeEmojiIndex;
  // 현재 드래그 중인지 여부
  bool _isDragging = false;
  // 회전 모드 여부
  bool _isRotating = false;
  // 회전 시작 각도
  double _startRotation = 0.0;
  // 회전 시작 위치
  Offset _startPosition = Offset.zero;

  // 60초 시간 제한을 위한 타이머 관련 변수
  Timer? _timer;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // 화면이 dispose될 때 타이머 취소
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          // 시간 초과 시에도 프레임 선택 화면으로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FrameSelectionScreen(
                shots: widget.shots,
                addedEmojis: _addedEmojis,
              ),
            ),
          );
        }
      });
    });
  }

  void _returnToLobby() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // 사진 영역 Stack의 크기 및 위치를 얻기 위한 GlobalKey (필요 시 사용)
  // final GlobalKey _photoAreaKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // 여기서 전달받은 shots 데이터를 사용하여 이모티콘 편집 UI를 구현합니다.
    // 현재는 간단한 화면 표시만 합니다.

    final currentShot = widget.shots.isNotEmpty ? widget.shots[_currentIndex] : null;
    final displayImageBytes = currentShot?.edited ?? currentShot?.original; // 편집된 사진 우선 표시, 없으면 원본

    return Scaffold(
      appBar: AppBar(
        title: Text('이모티콘 추가 ($_remainingSeconds초)'), // 남은 시간 표시
        actions: [
          // TODO: 최종 완료 및 저장/공유 버튼 추가
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              // TODO: 이모지 편집 결과 저장 로직 제거, 프레임 선택 화면으로 이동
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FrameSelectionScreen(
                    shots: widget.shots, // 원본 사진 데이터
                    addedEmojis: _addedEmojis, // 추가된 이모티콘 데이터
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 현재 사진 표시 및 이모티콘 추가 영역
          Expanded(
            child: Stack(
              // key: _photoAreaKey, // GlobalKey 할당
              children: [
                // 배경 이미지로 현재 편집 중인 사진 표시
                if (displayImageBytes != null)
                  Positioned.fill(
                    child: Image.memory(
                       displayImageBytes,
                       // key: _imageKey, // Image.memory에 GlobalKey 할당
                       fit: BoxFit.contain,
                    ),
                  )
                else
                  const Center(child: Text('사진 없음', style: TextStyle(color: Colors.white))),

                // TODO: 이모티콘 위젯들을 올릴 영역 (GestureDetector 등을 사용하여 배치, 이동, 크기 조절 구현)

                // 사진 영역에 탭 제스처 감지
                Positioned.fill(
                  child: GestureDetector(
                    onTapUp: (details) {
                      // 사진 탭 시 이모티콘 추가 로직
                      if (_selectedEmojiToPlace != null && currentShot != null) {
                        // 탭 위치 (GestureDetector 기준 로컬 좌표)를 이모티콘 위치로 사용
                        final tapPosition = details.localPosition;
                        print('GestureDetector 로컬 탭 위치: $tapPosition');

                        // TODO: Image fit: BoxFit.contain에 따라 이미지가 표시되는 실제 영역과
                        // 위젯 경계 간의 차이를 고려하여 정확한 배치 위치 보정 필요
 
                        setState(() {
                          _addedEmojis.update(
                            _currentIndex,
                            (list) => [...list, {
                              'emoji': _selectedEmojiToPlace!,
                              'position': tapPosition, // GestureDetector 로컬 좌표에 배치
                              'size': 40.0, // 기본 크기
                              'rotation': 0.0,
                            }],
                            ifAbsent: () => [{
                              'emoji': _selectedEmojiToPlace!,
                              'position': tapPosition,
                              'size': 40.0,
                              'rotation': 0.0,
                            }],
                          );
                          _selectedEmojiToPlace = null; // 이모티콘 배치 후 선택 해제
                          _activeEmojiIndex = null; // 새 이모티콘 추가 후 활성 해제
                        });
                        print('이모티콘 $_selectedEmojiToPlace이(가) 탭 위치 $tapPosition에 추가되었습니다.');
                      } else if (_selectedEmojiToPlace == null) {
                        // TODO: 배치된 이모티콘이 탭되었는지 확인 및 편집 활성화
                        // 배치된 이모티콘이 아닌 사진 배경을 탭한 경우, 활성 이모티콘 해제
                        setState(() {
                          _activeEmojiIndex = null; // 활성 이모티콘 해제
                          print('사진 배경 탭됨. 활성 이모티콘 해제.');
                        });
                      }
                    },
                  ),
                ),

                // 현재 사진에 추가된 이모티콘 표시
                ...(_addedEmojis[_currentIndex] ?? []).asMap().entries.map((entry) {
                  final index = entry.key;
                  final emojiData = entry.value;
                  final emoji = emojiData['emoji'] as String;
                  final position = emojiData['position'] as Offset;
                  final size = emojiData['size'] as double;
                  final rotation = emojiData['rotation'] as double;

                  return Positioned(
                    left: position.dx,
                    top: position.dy,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeEmojiIndex = index;
                          _isRotating = false;
                        });
                      },
                      onPanStart: (details) {
                        if (_activeEmojiIndex == index) {
                          setState(() {
                            _isDragging = true;
                            _startPosition = details.localPosition;
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (_isDragging && _activeEmojiIndex == index) {
                          setState(() {
                            final currentEmojis = _addedEmojis[_currentIndex]!;
                            final newPosition = Offset(
                              position.dx + details.delta.dx,
                              position.dy + details.delta.dy,
                            );
                            currentEmojis[index]['position'] = newPosition;
                          });
                        }
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _isDragging = false;
                        });
                      },
                      child: Stack(
                        children: [
                          Transform.rotate(
                            angle: rotation,
                            child: Text(
                              emoji,
                              style: TextStyle(fontSize: size),
                            ),
                          ),
                          if (_activeEmojiIndex == index)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          if (_activeEmojiIndex == index)
                            Positioned(
                              right: -20,
                              top: -20,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _isRotating = true;
                                    _startRotation = rotation;
                                    _startPosition = details.localPosition;
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (_isRotating && _activeEmojiIndex == index) {
                                    setState(() {
                                      final currentEmojis = _addedEmojis[_currentIndex]!;
                                      final center = Offset(size / 2, size / 2);
                                      final startAngle = (_startPosition - center).direction;
                                      final currentAngle = (details.localPosition - center).direction;
                                      final angleDiff = currentAngle - startAngle;
                                      currentEmojis[index]['rotation'] = _startRotation + angleDiff;
                                    });
                                  }
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _isRotating = false;
                                  });
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.rotate_right,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          if (_activeEmojiIndex == index)
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: GestureDetector(
                                onPanStart: (details) {
                                  setState(() {
                                    _isDragging = true;
                                    _startPosition = details.localPosition;
                                  });
                                },
                                onPanUpdate: (details) {
                                  if (_isDragging && _activeEmojiIndex == index) {
                                    setState(() {
                                      final currentEmojis = _addedEmojis[_currentIndex]!;
                                      final delta = details.localPosition - _startPosition;
                                      final scale = 1.0 + (delta.dx + delta.dy) / 100;
                                      final newSize = (size * scale).clamp(20.0, 200.0);
                                      currentEmojis[index]['size'] = newSize;
                                    });
                                  }
                                },
                                onPanEnd: (_) {
                                  setState(() {
                                    _isDragging = false;
                                  });
                                },
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              ],
            ),
          ),
          // TODO: 배치된 이모티콘 편집 테스트를 위한 임시 컨트롤 (크기 조절, 회전)
          if (_activeEmojiIndex != null) // 활성 이모티콘이 있을 때만 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 크기 감소 버튼
                  IconButton(
                    icon: const Icon(Icons.zoom_out),
                    onPressed: () {
                      setState(() {
                        final currentEmojis = _addedEmojis[_currentIndex]!;
                        double currentSize = currentEmojis[_activeEmojiIndex!]['size'];
                        currentEmojis[_activeEmojiIndex!]['size'] = (currentSize - 5.0).clamp(10.0, 200.0);
                      });
                    },
                  ),
                  // 크기 증가 버튼
                  IconButton(
                    icon: const Icon(Icons.zoom_in),
                    onPressed: () {
                      setState(() {
                        final currentEmojis = _addedEmojis[_currentIndex]!;
                        double currentSize = currentEmojis[_activeEmojiIndex!]['size'];
                        currentEmojis[_activeEmojiIndex!]['size'] = (currentSize + 5.0).clamp(10.0, 200.0);
                      });
                    },
                  ),
                  const SizedBox(width: 20),
                  // 반시계 방향 회전 버튼
                  IconButton(
                    icon: const Icon(Icons.rotate_left),
                    onPressed: () {
                      setState(() {
                        final currentEmojis = _addedEmojis[_currentIndex]!;
                        double currentRotation = currentEmojis[_activeEmojiIndex!]['rotation'];
                        currentEmojis[_activeEmojiIndex!]['rotation'] = currentRotation - 0.1; // 라디안 값 감소
                      });
                    },
                  ),
                  // 시계 방향 회전 버튼
                  IconButton(
                    icon: const Icon(Icons.rotate_right),
                    onPressed: () {
                      setState(() {
                        final currentEmojis = _addedEmojis[_currentIndex]!;
                        double currentRotation = currentEmojis[_activeEmojiIndex!]['rotation'];
                        currentEmojis[_activeEmojiIndex!]['rotation'] = currentRotation + 0.1; // 라디안 값 증가
                      });
                    },
                  ),
                ],
              ),
            ),
          // 사진 인덱스 및 페이지 넘기기 컨트롤
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _currentIndex > 0
                      ? () {
                          setState(() {
                            _currentIndex--;
                          });
                        }
                      : null, // 첫 번째 사진에서는 뒤로가기 비활성화
                ),
                Text(
                  '사진 ${_currentIndex + 1} / ${widget.shots.length}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _currentIndex < widget.shots.length - 1
                      ? () {
                          setState(() {
                            _currentIndex++;
                          });
                        }
                      : null, // 마지막 사진에서는 앞으로가기 비활성화
                ),
              ],
            ),
          ),
          // TODO: 이모티콘 선택 팔레트 또는 리스트 표시 영역 추가
          // 이모티콘 선택 팔레트
          Container(
            height: 80,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableEmojis.length,
              itemBuilder: (context, index) {
                final emoji = _availableEmojis[index];
                return GestureDetector(
                  onTap: () {
                    print('이모티콘 팔레트에서 \'$emoji\' 선택됨');
                    // 이모티콘을 현재 사진 중앙에 추가
                    // final photoWidgetSize = (context.findRenderObject() as RenderBox).size;
                    // 간단하게 화면 중앙으로 초기 위치 설정 (정확한 사진 중앙 위치는 추가 계산 필요)
                    setState(() {
                      _selectedEmojiToPlace = emoji;
                    });
                    print('_selectedEmojiToPlace 상태 업데이트: $_selectedEmojiToPlace');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 30.0), // 팔레트 이모티콘 크기
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 