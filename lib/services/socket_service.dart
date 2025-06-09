import 'dart:typed_data';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final socketServiceProvider = Provider<SocketService>((_) => SocketService());

typedef PhotoCallback = void Function(int index, Uint8List bytes);

class SocketService {
  PhotoCallback? _onPhoto;
  bool _isConnected = false;
  Socket? _socket;
  Uint8List _receiveBuffer = Uint8List(0);
  static const String _host = '10.42.0.1';
  static const int _port = 5001;

  /// 소켓 연결 상태 확인
  Future<bool> isConnected() async {
    return _isConnected && _socket != null;
  }

  /// 소켓 연결 해제
  Future<void> disconnect() async {
    try {
      if (_socket != null) {
        await _socket?.close();
        _socket = null;
        _isConnected = false;
        print('소켓 연결 해제 완료');
      }
    } catch (e) {
      print('소켓 연결 해제 중 오류: $e');
    }
  }

  /// (1) 소켓 연결 & 수신 콜백 등록
  Future<void> connect(PhotoCallback onPhotoReceived) async {
    if (_socket != null) {
      print('이미 연결된 소켓이 있습니다. 연결을 종료합니다.');
      await disconnect();
    }

    try {
    _onPhoto = onPhotoReceived;
      print('소켓 연결 시도: $_host:$_port');
      
      // 새로운 연결 시도
      _socket = await Socket.connect(
        _host,
        _port,
        timeout: const Duration(seconds: 5),
      );
      
      // 연결 성공 시 소켓 옵션 설정
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      
      print('소켓 연결 성공!');
      print('로컬 주소: ${_socket!.address.address}:${_socket!.port}');
      print('원격 주소: ${_socket!.remoteAddress.address}:${_socket!.remotePort}');
      _isConnected = true;
      
      // 수신 스레드 시작
      _startReceiveThread();
    } catch (e) {
      _isConnected = false;
      print('소켓 연결 실패: $e');
      rethrow;
    }
  }

  void _startReceiveThread() {
    if (_socket == null) {
      print('소켓이 null입니다. 수신 스레드를 시작할 수 없습니다.');
      return;
    }
    
    print('수신 스레드 시작');
    _receiveBuffer = Uint8List(0);

    _socket!.listen(
      (data) {
        print('데이터 수신: ${data.length} bytes');
        _receiveBuffer = Uint8List.fromList([..._receiveBuffer, ...data]);
        print('현재 버퍼 크기: ${_receiveBuffer.length} bytes');

        _processBuffer();
      },
      onError: (error) {
        print('소켓 수신 오류: $error');
        _isConnected = false;
      },
      onDone: () {
        print('소켓 연결 종료');
        _isConnected = false;
      },
    );
  }

  void _processBuffer() {
    while (_receiveBuffer.length >= 4) {
      final length = (_receiveBuffer[0] << 24) | (_receiveBuffer[1] << 16) | (_receiveBuffer[2] << 8) | _receiveBuffer[3];
      print('버퍼에서 읽은 이미지 예상 크기: $length bytes');

      if (_receiveBuffer.length >= 4 + length) {
        print('완전한 이미지 데이터 수신됨: ${length} bytes');

        final imageData = _receiveBuffer.sublist(4, 4 + length);
        print('이미지 데이터 추출 완료: ${imageData.length} bytes');

        _onPhoto?.call(_lastRequestedIndex, Uint8List.fromList(imageData));

        _receiveBuffer = _receiveBuffer.sublist(4 + length);
        print('처리 후 남은 버퍼 크기: ${_receiveBuffer.length} bytes');
      } else {
        print('완전한 이미지 데이터를 기다리는 중... (현재 버퍼 크: ${_receiveBuffer.length} bytes)');
        break;
      }
    }
  }

  int _lastRequestedIndex = 0;

  /// (2) N번째 사진 촬영 요청
  void requestPhoto(int index) {
    if (!_isConnected || _socket == null) {
      print('소켓이 연결되어 있지 않습니다');
      return;
    }
    
    try {
      _lastRequestedIndex = index;
      _socket!.add(Uint8List.fromList([0x01, index])); // 0x01 명령과 인덱스 전송
    } catch (e) {
      print('사진 요청 실패: $e');
      _isConnected = false;
    }
  }

  /// (3) 카운트다운 숫자 전송
  void sendCountdown(int seconds) {
    if (!_isConnected || _socket == null) {
      print('소켓이 연결되어 있지 않습니다');
      return;
    }
    try {
      _socket!.add(Uint8List.fromList([0x02, seconds])); // 0x02 명령과 초 전송
    } catch (e) {
      print('카운트다운 전송 실패: $e');
      _isConnected = false;
    }
  }

  /// (4) 세션 종료 신호 전송
  void sendSessionEnd() {
    if (!_isConnected || _socket == null) {
      print('소켓이 연결되어 있지 않습니다');
      return;
    }
    try {
      _socket!.add(Uint8List.fromList([0x03])); // 0x03 명령 전송
      disconnect(); // 신호 전송 후 연결 해제
    } catch (e) {
      print('세션 종료 신호 전송 실패: $e');
      _isConnected = false;
    }
  }

  void dispose() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
  }
}
