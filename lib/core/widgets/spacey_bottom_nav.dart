import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SpaceyBottomNav extends StatelessWidget {
  final int currentIndex;
  const SpaceyBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF1E1E2E),
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (i) {
        if (i == currentIndex) return;
        switch (i) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/focus');
            break;
          case 2:
            context.go('/nebula');
            break;
          case 3:
            context.go('/galaxy');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.rocket_launch),
          label: 'Missions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.timer_outlined),
          label: 'Focus',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.cloud_circle_outlined),
          label: 'Nebula',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          label: 'Galaxy',
        ),
      ],
    );
  }
}
