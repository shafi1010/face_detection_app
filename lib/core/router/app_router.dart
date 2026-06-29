import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/alerts_screen.dart';
import '../../screens/camera_view_screen.dart';
import '../../screens/cameras_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/enrollment_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter create(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isSplash = state.matchedLocation.startsWith('/splash');
        final isLogin = state.matchedLocation.startsWith('/login');

        if (isSplash) return null;

        if (!isLoggedIn && !isLogin) return '/login';
        if (isLoggedIn && isLogin) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (_, __) => const LoginScreen(),
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (_, __, child) => DashboardShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (_, __) => NoTransitionPage(
                key: const ValueKey('dashboard'),
                child: const DashboardScreen(),
              ),
            ),
            GoRoute(
              path: '/cameras',
              pageBuilder: (_, __) => NoTransitionPage(
                key: const ValueKey('cameras'),
                child: const CamerasScreen(),
              ),
              routes: [
                GoRoute(
                  path: ':cameraId',
                  builder: (_, state) => CameraViewScreen(
                    cameraId: state.pathParameters['cameraId']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/alerts',
              pageBuilder: (_, __) => NoTransitionPage(
                key: const ValueKey('alerts'),
                child: const AlertsScreen(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (_, __) => NoTransitionPage(
                key: const ValueKey('settings'),
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/enroll',
          builder: (_, __) => const EnrollmentScreen(),
        ),
      ],
    );
  }
}

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/cameras')) currentIndex = 1;
    if (location.startsWith('/alerts')) currentIndex = 2;
    if (location.startsWith('/settings')) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0: context.go('/dashboard');
            case 1: context.go('/cameras');
            case 2: context.go('/alerts');
            case 3: context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Cameras',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
