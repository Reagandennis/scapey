import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'features/missions/missions_screen.dart';
import 'features/focus/focus_timer.dart';
import 'features/nebula/nebula_screen.dart';
import 'features/galaxy/galaxy_map_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MissionsScreen(),
    ),
    GoRoute(
      path: '/focus',
      builder: (context, state) => const FocusTimerScreen(),
    ),
    GoRoute(
      path: '/nebula',
      builder: (context, state) => const NebulaScreen(),
    ),
    GoRoute(
      path: '/galaxy',
      builder: (context, state) => const GalaxyMapScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
