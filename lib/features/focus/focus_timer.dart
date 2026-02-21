import 'dart:async';
import 'package:flutter/material.dart';

class FocusTimerScreen extends StatefulWidget {
  const FocusTimerScreen({super.key});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  int seconds = 1500; // 25 mins
  Timer? timer;

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds > 0) {
        setState(() => seconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deep Space Focus')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(
                fontSize: 64, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF00C2FF)
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: startTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Launch Mission", 
                style: TextStyle(fontSize: 20, color: Colors.white)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
