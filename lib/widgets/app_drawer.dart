import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;

    return Drawer(
      backgroundColor: AppTheme.surfaceVariant,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      (auth.user?.name.isNotEmpty == true ? auth.user!.name[0] : '?').toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.name ?? 'Operator',
                          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          auth.user?.email ?? '',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            _drawerItem(
              context,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              path: '/dashboard',
              selected: location == '/dashboard',
            ),
            _drawerItem(
              context,
              icon: Icons.videocam_outlined,
              label: 'Cameras',
              path: '/cameras',
              selected: location.startsWith('/cameras'),
            ),
            _drawerItem(
              context,
              icon: Icons.notifications_outlined,
              label: 'Alerts',
              path: '/alerts',
              selected: location.startsWith('/alerts'),
            ),
            _drawerItem(
              context,
              icon: Icons.person_add_outlined,
              label: 'Enroll Face',
              path: '/enroll',
              selected: location == '/enroll',
            ),
            const Spacer(),
            const Divider(),
            _drawerItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              path: '/settings',
              selected: location.startsWith('/settings'),
            ),
            _drawerItem(
              context,
              icon: Icons.logout,
              label: 'Sign Out',
              onTap: () async {
                Navigator.pop(context);
                await auth.logout();
                if (context.mounted) context.go('/login');
              },
              color: AppTheme.error,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? path,
    bool selected = false,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: color ?? (selected ? AppTheme.primary : AppTheme.textSecondary)),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? (selected ? AppTheme.primary : AppTheme.textPrimary),
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      dense: true,
      onTap: onTap ?? () {
        Navigator.pop(context);
        if (path != null) context.go(path);
      },
    );
  }
}
