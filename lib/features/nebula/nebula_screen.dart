import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NebulaScreen extends StatelessWidget {
  const NebulaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Idea Nebula')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Brain Dump -> Structured Plan',
                style: TextStyle(fontSize: 20, color: Color(0xFF00C2FF)),
              ),
              SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter your random thoughts here...',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6C5CE7)),
                  ),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E2E),
        selectedItemColor: const Color(0xFF6C5CE7),
        unselectedItemColor: Colors.grey,
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/'); break;
            case 1: break;
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
