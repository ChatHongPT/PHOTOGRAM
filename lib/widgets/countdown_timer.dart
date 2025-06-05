// widgets/countdown_timer.dart
import 'package:flutter/material.dart';

class CountdownTimer extends StatelessWidget {
  final int seconds;
  const CountdownTimer({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54, width: 1.5),
        ),
        child: Text(
          '남은 시간: $seconds초',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
