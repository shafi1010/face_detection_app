import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/camera.dart';
import 'status_indicator.dart';

class CameraCard extends StatelessWidget {
  final Camera camera;
  final VoidCallback? onTap;

  const CameraCard({
    super.key,
    required this.camera,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 56,
                decoration: BoxDecoration(
                  color: camera.thumbnailUrl != null ? Colors.transparent : AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: camera.thumbnailUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          camera.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderIcon(),
                        ),
                      )
                    : _placeholderIcon(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (camera.location != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        camera.location!,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        StatusIndicator(
                          isActive: camera.status == CameraStatus.online,
                          size: 8,
                          activeColor: camera.status == CameraStatus.online
                              ? AppTheme.online
                              : camera.status == CameraStatus.error
                                  ? AppTheme.error
                                  : AppTheme.offline,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusLabel(camera.status),
                          style: TextStyle(
                            fontSize: 11,
                            color: camera.status == CameraStatus.online
                                ? AppTheme.online
                                : camera.status == CameraStatus.error
                                    ? AppTheme.error
                                    : AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (camera.isDetecting)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(Icons.videocam, color: AppTheme.textMuted, size: 24),
    );
  }

  String _statusLabel(CameraStatus status) {
    switch (status) {
      case CameraStatus.online: return 'Online';
      case CameraStatus.offline: return 'Offline';
      case CameraStatus.error: return 'Error';
      case CameraStatus.disabled: return 'Disabled';
    }
  }
}
