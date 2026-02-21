import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mission Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Commander, your missions await.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/focus'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C2FF),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              child: const Text('Enter Deep Space Mode', style: TextStyle(color: Color(0xFF0D0D1A))),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0: break;
            case 1: context.go('/nebula'); break;
            case 2: context.go('/galaxy'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.rocket_launch), label: 'Missions'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_circle), label: 'Nebula'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Galaxy'),
        ],
      ),
    );
  }
}
