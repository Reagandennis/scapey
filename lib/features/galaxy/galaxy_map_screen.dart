import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GalaxyMapScreen extends StatelessWidget {
  const GalaxyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Galaxy Map')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map, size: 100, color: Color(0xFF6C5CE7)),
            SizedBox(height: 20),
            Text(
              'Galaxy Map Visualization',
              style: TextStyle(fontSize: 20, color: Color(0xFFEAEAEA)),
            ),
            Text(
              '(CustomPainter placeholder)',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/'); break;
            case 1: context.go('/nebula'); break;
            case 2: break;
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
