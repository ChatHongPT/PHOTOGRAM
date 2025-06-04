import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final socketServiceProvider = Provider((ref) => SocketService());

class SocketService {
  WebSocketChannel? channel;

  void connect(void Function(int, Uint8List) onPhoto) {
    channel = WebSocketChannel.connect(
      Uri.parse('ws://raspberrypi.local:5000/ws'),
    );
    channel!.stream.listen((event) {
      final map = jsonDecode(event);
      if (map['type'] == 'photo') {
        final idx = map['index'];
        final bytes = base64Decode(map['data']);
        onPhoto(idx, bytes);
      }
    });
  }

  void dispose() => channel?.sink.close();
}
