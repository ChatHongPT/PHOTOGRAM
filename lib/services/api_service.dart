import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  final baseUrl = 'http://raspberrypi.local:5000';

  Future<void> confirmSession(String uuid) async {
    await http.post(Uri.parse('$baseUrl/confirm'), body: {'uuid': uuid});
  }
}
