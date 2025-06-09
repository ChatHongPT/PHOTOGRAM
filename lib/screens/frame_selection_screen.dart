import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shot.dart';

class FrameSelectionScreen extends StatefulWidget {
  final List<Shot> shots;
  final Map<int, List<Map<String, dynamic>>> addedEmojis;

  const FrameSelectionScreen({
    Key? key,
    required this.shots,
    required this.addedEmojis,
  }) : super(key: key);

  @override
  State<FrameSelectionScreen> createState() => _FrameSelectionScreenState();
}

class _FrameSelectionScreenState extends State<FrameSelectionScreen> {
  final List<String> _framePaths = [
    'assets/images/frame1.png',
    'assets/images/frame2.png',
    'assets/images/frame3.png',
    'assets/images/frame4.png',
  ];
  String? _selectedFramePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFramePath = _framePaths.first; // 기본 프레임 선택
  }

  Future<Uint8List?> _createAndSaveCombinedImage(String framePath) async {
    // 최종 이미지의 크기 및 패딩 정의
    const double singleShotWidth = 300.0; // 각 사진의 너비
    const double singleShotHeight = 300.0; // 각 사진의 높이
    const double spacing = 10.0; // 사진 간 간격
    const double framePadding = 20.0; // 전체 프레임 패딩

    final double totalWidth = (singleShotWidth * 2) + spacing + (framePadding * 2);
    final double totalHeight = (singleShotHeight * 2) + spacing + (framePadding * 2);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth, totalHeight));

    // 프레임 이미지 로드 및 그리기
    final ByteData frameByteData = await rootBundle.load(framePath);
    final Uint8List framePngBytes = frameByteData.buffer.asUint8List();
    final ui.Codec frameCodec = await ui.instantiateImageCodec(framePngBytes);
    final ui.FrameInfo frameInfo = await frameCodec.getNextFrame();
    final ui.Image frameImage = frameInfo.image;

    canvas.drawImageRect(
      frameImage,
      Rect.fromLTWH(0, 0, frameImage.width.toDouble(), frameImage.height.toDouble()),
      Rect.fromLTWH(0, 0, totalWidth, totalHeight),
      Paint(),
    );

    // 프레임 패딩 내부에 그리기 위한 캔버스 이동
    canvas.translate(framePadding, framePadding);

    // 4컷 사진의 위치 (프레임 내부에 맞춰 조정 필요)
    final List<Offset> shotPositions = [
      Offset(0, 0), // 좌상단
      Offset(singleShotWidth + spacing, 0), // 우상단
      Offset(0, singleShotHeight + spacing), // 좌하단
      Offset(singleShotWidth + spacing, singleShotHeight + spacing), // 우하단
    ];

    try {
      for (int i = 0; i < widget.shots.length; i++) {
        final shot = widget.shots[i];
        final displayImageBytes = shot.edited ?? shot.original;

        if (displayImageBytes != null) {
          final ui.Codec codec = await ui.instantiateImageCodec(displayImageBytes);
          final ui.FrameInfo frameInfo = await codec.getNextFrame();
          final ui.Image shotImage = frameInfo.image;

          final Rect srcRect = Rect.fromLTWH(0, 0, shotImage.width.toDouble(), shotImage.height.toDouble());
          final Rect dstRect = Rect.fromLTWH(shotPositions[i].dx, shotPositions[i].dy, singleShotWidth, singleShotHeight);
          canvas.drawImageRect(shotImage, srcRect, dstRect, Paint());

          final emojisOnShot = widget.addedEmojis[i] ?? [];
          for (final emojiData in emojisOnShot) {
            final emoji = emojiData['emoji'] as String;
            final position = emojiData['position'] as Offset;
            final size = emojiData['size'] as double;
            final rotation = emojiData['rotation'] as double;

            final Offset globalEmojiPosition = Offset(
              shotPositions[i].dx + position.dx,
              shotPositions[i].dy + position.dy,
            );

            final TextPainter textPainter = TextPainter(
              text: TextSpan(
                text: emoji,
                style: TextStyle(fontSize: size, color: Colors.black),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();

            canvas.save();
            canvas.translate(
              globalEmojiPosition.dx + (textPainter.width / 2),
              globalEmojiPosition.dy + (textPainter.height / 2),
            );
            canvas.rotate(rotation);
            canvas.translate(
              -(textPainter.width / 2),
              -(textPainter.height / 2),
            );
            textPainter.paint(canvas, Offset.zero);
            canvas.restore();
          }
        }
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image img = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
      final ByteData? byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final result = await ImageGallerySaver.saveImage(pngBytes, quality: 90, name: "Photogram_Framed_${DateTime.now().toIso8601String()}");
        print("갤러리 저장 결과: $result");

        if (result['isSuccess']) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String> savedImageNames = prefs.getStringList('savedImageNames') ?? [];
          String? savedFilePath = result['filePath'];
          if (savedFilePath != null) {
            savedImageNames.add(savedFilePath);
            await prefs.setStringList('savedImageNames', savedImageNames);
            print("SharedPreferences에 저장된 이미지 목록: $savedImageNames");
          }
        }
        return pngBytes;
      }
    } catch (e) {
      print("결합 이미지 생성 및 저장 오류: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('프레임 선택'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    '사진을 저장 중입니다...',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _selectedFramePath != null
                        ? Image.asset(
                            _selectedFramePath!,
                            fit: BoxFit.contain,
                            height: 300,
                          )
                        : const Text(
                            '프레임을 선택해주세요.',
                            style: TextStyle(color: Colors.white70),
                          ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '프레임을 선택하세요',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _framePaths.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedFramePath = _framePaths[index];
                                });
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedFramePath == _framePaths[index]
                                        ? Colors.blue
                                        : Colors.white,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _framePaths[index],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (_selectedFramePath != null) {
                                    setState(() {
                                      _isSaving = true;
                                    });
                                    await _createAndSaveCombinedImage(_selectedFramePath!);
                                    setState(() {
                                      _isSaving = false;
                                    });
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 