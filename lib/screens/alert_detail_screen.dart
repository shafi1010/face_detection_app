import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_theme.dart';
import '../models/alert.dart';
import '../providers/alert_provider.dart';

class AlertDetailScreen extends StatelessWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AlertProvider>();
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return Scaffold(
      appBar: AppBar(
        title: Text(_typeLabel(alert.type)),
        actions: [
          if (alert.status == AlertStatus.unacknowledged)
            TextButton(
              onPressed: () => provider.acknowledgeAlert(alert.id),
              child: const Text('Acknowledge'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSeverityBanner(),
          const SizedBox(height: 20),
          if (alert.faceMatch != null) ...[
            _buildFaceMatchSection(),
            const SizedBox(height: 16),
          ],
          if (alert.snapshotUrl != null) ...[
            _buildSnapshot(),
            const SizedBox(height: 16),
          ],
          _buildInfoCard(dateFormat),
          const SizedBox(height: 16),
          if (alert.metadata.isNotEmpty) _buildMetadataCard(),
        ],
      ),
    );
  }

  Widget _buildSeverityBanner() {
    final colors = switch (alert.severity) {
      AlertSeverity.critical => (bg: AppTheme.alertCritical.withValues(alpha: 0.15), border: AppTheme.alertCritical.withValues(alpha: 0.3), text: AppTheme.alertCritical),
      AlertSeverity.warning => (bg: AppTheme.alertWarning.withValues(alpha: 0.15), border: AppTheme.alertWarning.withValues(alpha: 0.3), text: AppTheme.alertWarning),
      AlertSeverity.info => (bg: AppTheme.alertInfo.withValues(alpha: 0.15), border: AppTheme.alertInfo.withValues(alpha: 0.3), text: AppTheme.alertInfo),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(
            alert.severity == AlertSeverity.critical ? Icons.gpp_bad : Icons.info_outline,
            color: colors.text,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${alert.severity.name.toUpperCase()} ALERT',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaceMatchSection() {
    final match = alert.faceMatch!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: match.isBlacklisted ? AppTheme.alertCritical.withValues(alpha: 0.3) : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: match.photoUrl != null
                ? CachedNetworkImage(
                    imageUrl: match.photoUrl!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppTheme.surface,
                      child: const Icon(Icons.person, color: AppTheme.textMuted),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppTheme.surface,
                      child: const Icon(Icons.person, color: AppTheme.textMuted),
                    ),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.surface,
                    child: const Icon(Icons.person, color: AppTheme.textMuted, size: 32),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      match.personName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (match.isBlacklisted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.alertCritical.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BLACKLIST',
                          style: TextStyle(
                            color: AppTheme.alertCritical,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Match confidence:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      '${(match.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: match.confidence > 0.85 ? AppTheme.primary : AppTheme.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (match.notes != null && match.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    match.notes!,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshot() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: alert.snapshotUrl!,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 220,
          color: AppTheme.surface,
          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 220,
          color: AppTheme.surface,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, color: AppTheme.textMuted, size: 32),
              SizedBox(height: 8),
              Text('Failed to load image', style: TextStyle(color: AppTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _infoRow('Camera', alert.cameraName),
          _infoRow('Type', _typeLabel(alert.type)),
          _infoRow('Timestamp', dateFormat.format(alert.timestamp)),
          _infoRow('Status', alert.status.name.toUpperCase()),
          if (alert.confidence != null) _infoRow('Confidence', '${(alert.confidence! * 100).toStringAsFixed(1)}%'),
          if (alert.acknowledgedAt != null) _infoRow('Acknowledged', dateFormat.format(alert.acknowledgedAt!)),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metadata',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          ...alert.metadata.entries.map((e) => _infoRow(e.key, e.value.toString())),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(AlertType type) {
    switch (type) {
      case AlertType.blacklistMatch: return 'Blacklist Match';
      case AlertType.watchlistMatch: return 'Watchlist Match';
      case AlertType.unknownFace: return 'Unknown Face';
      case AlertType.crowdDensity: return 'Crowd Density';
      case AlertType.dwellTime: return 'Dwell Time';
      case AlertType.loitering: return 'Loitering';
      case AlertType.zoneViolation: return 'Zone Violation';
    }
  }
}
