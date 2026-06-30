import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onAcknowledge;

  const AlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final isUnacknowledged = alert.status == AlertStatus.unacknowledged;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnacknowledged
                ? Border(
                    left: BorderSide(
                      color: alert.severity == AlertSeverity.critical
                          ? AppTheme.alertCritical
                          : AppTheme.alertWarning,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _severityColor().withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_severityIcon(), color: _severityColor(), size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleText(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isUnacknowledged ? FontWeight.w600 : FontWeight.w400,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeFormat.format(alert.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alert.cameraName,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    if (alert.faceMatch != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            alert.faceMatch!.personName,
                            style: TextStyle(
                              color: alert.faceMatch!.isBlacklisted ? AppTheme.alertCritical : AppTheme.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(alert.faceMatch!.confidence * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnacknowledged && onAcknowledge != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 28,
                  child: TextButton(
                    onPressed: onAcknowledge,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppTheme.secondary,
                    ),
                    child: const Text('Ack', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical: return AppTheme.alertCritical;
      case AlertSeverity.warning: return AppTheme.alertWarning;
      case AlertSeverity.info: return AppTheme.alertInfo;
    }
  }

  IconData _severityIcon() {
    switch (alert.type) {
      case AlertType.blacklistMatch:
      case AlertType.watchlistMatch:
        return Icons.person_search;
      case AlertType.crowdDensity:
        return Icons.groups;
      case AlertType.dwellTime:
      case AlertType.loitering:
        return Icons.timer;
      case AlertType.zoneViolation:
        return Icons.do_not_disturb;
      case AlertType.unknownFace:
        return Icons.face;
    }
  }

  String _titleText() {
    switch (alert.type) {
      case AlertType.blacklistMatch: return 'Blacklist: ${alert.faceMatch?.personName ?? 'Unknown'}';
      case AlertType.watchlistMatch: return 'Watchlist: ${alert.faceMatch?.personName ?? 'Unknown'}';
      case AlertType.unknownFace: return 'Unknown face detected';
      case AlertType.crowdDensity: return 'Crowd density alert';
      case AlertType.dwellTime: return 'Dwell time exceeded';
      case AlertType.loitering: return 'Loitering detected';
      case AlertType.zoneViolation: return 'Zone violation';
    }
  }

  void _showDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _buildDetailScreen(),
      ),
    );
  }

  Widget _buildDetailScreen() {
    return _AlertDetailShell(alert: alert, onAcknowledge: onAcknowledge);
  }
}

class _AlertDetailShell extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onAcknowledge;

  const _AlertDetailShell({required this.alert, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
        actions: [
          if (alert.status == AlertStatus.unacknowledged && onAcknowledge != null)
            TextButton(
              onPressed: () {
                onAcknowledge!();
                Navigator.pop(context);
              },
              child: const Text('Acknowledge'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _severityColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _severityColor().withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(_severityIcon(), color: _severityColor(), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${alert.severity.name.toUpperCase()} ALERT — ${alert.message}',
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                _infoRow('Camera', alert.cameraName),
                _infoRow('Type', _titleText()),
                _infoRow('Time', dateFormat.format(alert.timestamp)),
                _infoRow('Status', alert.status.name.toUpperCase()),
                if (alert.confidence != null) _infoRow('Confidence', '${(alert.confidence! * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor() {
    switch (alert.severity) {
      case AlertSeverity.critical: return AppTheme.alertCritical;
      case AlertSeverity.warning: return AppTheme.alertWarning;
      case AlertSeverity.info: return AppTheme.alertInfo;
    }
  }

  IconData _severityIcon() {
    switch (alert.type) {
      case AlertType.blacklistMatch:
      case AlertType.watchlistMatch:
        return Icons.person_search;
      case AlertType.crowdDensity:
        return Icons.groups;
      case AlertType.dwellTime:
      case AlertType.loitering:
        return Icons.timer;
      case AlertType.zoneViolation:
        return Icons.do_not_disturb;
      case AlertType.unknownFace:
        return Icons.face;
    }
  }

  String _titleText() {
    switch (alert.type) {
      case AlertType.blacklistMatch: return 'Blacklist: ${alert.faceMatch?.personName ?? 'Unknown'}';
      case AlertType.watchlistMatch: return 'Watchlist: ${alert.faceMatch?.personName ?? 'Unknown'}';
      case AlertType.unknownFace: return 'Unknown face detected';
      case AlertType.crowdDensity: return 'Crowd density alert';
      case AlertType.dwellTime: return 'Dwell time exceeded';
      case AlertType.loitering: return 'Loitering detected';
      case AlertType.zoneViolation: return 'Zone violation';
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }
}
