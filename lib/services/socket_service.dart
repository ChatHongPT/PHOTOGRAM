import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socketServiceProvider = Provider<SocketService>((_) => SocketService());

typedef PhotoCallback = void Function(int index, Uint8List bytes);

class SocketService {
  PhotoCallback? _onPhoto;

  /// (1) 소켓 연결 & 수신 콜백 등록
  void connect(PhotoCallback onPhotoReceived) {
    _onPhoto = onPhotoReceived;
    // TODO: 실제 소켓 연결 + 리스너 구현
  }

  /// (2) N번째 사진 촬영 요청  ★ 새로 추가한 메서드
  ///
  /// 실제 장치로 “index 번째 컷을 찍어 달라”는 메시지를 보내야 합니다.
  /// 여기서는 데모용으로 2초 뒤 더미 이미지 전송.
  void requestPhoto(int index) {
    // TODO: 임베디드/서버와 연동해 촬영 명령 전송
    Future.delayed(const Duration(seconds: 2), () {
      // 더미 데이터(빈 바이트) → 실제 JPG/PNG bytes 가 오도록 수정
      _onPhoto?.call(index, Uint8List.fromList(List.filled(10, 0x80)));
    });
  }
}
