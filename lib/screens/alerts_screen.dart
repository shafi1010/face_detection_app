import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/alert_provider.dart';
import '../widgets/alert_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertProvider>().fetchAlerts(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          if (provider.unacknowledgedCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.alertCritical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.alertCritical.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${provider.unacknowledgedCount} new',
                  style: const TextStyle(
                    color: AppTheme.alertCritical,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchAlerts(refresh: true),
        color: AppTheme.primary,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(AlertProvider provider) {
    if (provider.isLoading && provider.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.error != null && provider.alerts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => provider.fetchAlerts(refresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.alerts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'No alerts',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'All clear — no detections recorded',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll is ScrollEndNotification && scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 200) {
          provider.fetchMoreAlerts();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: provider.alerts.length,
        itemBuilder: (_, index) => AlertCard(
          alert: provider.alerts[index],
          onAcknowledge: () => provider.acknowledgeAlert(provider.alerts[index].id),
        ),
      ),
    );
  }
}
