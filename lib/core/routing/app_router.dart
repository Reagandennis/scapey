import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/missions/missions_screen.dart';
import '../../features/focus/focus_timer.dart';
import '../../features/nebula/nebula_screen.dart';
import '../../features/galaxy/galaxy_map_screen.dart';
import '../../features/auth/auth_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (session == null && !isAuthRoute) {
         return '/auth';
      }
      if (session != null && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
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
}
