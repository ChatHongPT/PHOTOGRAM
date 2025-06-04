import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ResultScreen extends StatelessWidget {
  final String url;
  const ResultScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 코드')),
      body: Center(
        child: QrImageView(data: url, version: QrVersions.auto, size: 280),
      ),
    );
  }
}
