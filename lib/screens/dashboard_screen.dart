import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/camera_provider.dart';
import '../widgets/alert_card.dart';
import '../widgets/metric_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<CameraProvider>().fetchCameras(),
      context.read<AlertProvider>().fetchAlerts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cameras = context.watch<CameraProvider>();
    final alerts = context.watch<AlertProvider>();

    final recentAlerts = alerts.alerts.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Good ${_greeting()}, ${auth.user?.name.split(' ').first ?? 'Operator'}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (cameras.isLoading && cameras.cameras.isEmpty)
              ..._buildShimmerGrid()
            else
              _buildMetricGrid(cameras, alerts),
            if (recentAlerts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Alerts',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              ...recentAlerts.map((alert) => AlertCard(alert: alert)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextButton.icon(
                  onPressed: () => context.go('/alerts'),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: const Text('View all alerts'),
                ),
              ),
            ],
            if (recentAlerts.isEmpty && !alerts.isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: AppTheme.primary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'No recent alerts',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Widget _buildMetricGrid(CameraProvider cameras, AlertProvider alerts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Online Cameras',
                  value: '${cameras.onlineCount}',
                  icon: Icons.videocam,
                  color: AppTheme.online,
                  subtitle: '${cameras.cameras.length} total',
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Alerts Today',
                  value: '${alerts.alerts.length}',
                  icon: Icons.warning_amber_rounded,
                  color: alerts.criticalAlerts.isNotEmpty ? AppTheme.alertCritical : AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Unacknowledged',
                  value: '${alerts.unacknowledgedCount}',
                  icon: Icons.notifications_active,
                  color: alerts.unacknowledgedCount > 0 ? AppTheme.alertCritical : AppTheme.textMuted,
                ),
              ),
              Expanded(
                child: MetricTile(
                  label: 'Offline Cameras',
                  value: '${cameras.offlineCount}',
                  icon: Icons.videocam_off,
                  color: cameras.offlineCount > 0 ? AppTheme.alertWarning : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildShimmerGrid() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Row(
              children: List.generate(2, (_) => const Expanded(child: MetricTile(label: '', value: '', icon: Icons.circle, color: AppTheme.textMuted))),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(2, (_) => const Expanded(child: MetricTile(label: '', value: '', icon: Icons.circle, color: AppTheme.textMuted))),
            ),
          ],
        ),
      ),
    ];
  }
}
