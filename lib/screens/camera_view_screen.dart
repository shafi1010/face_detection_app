import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';

class CameraViewScreen extends StatefulWidget {
  final String cameraId;

  const CameraViewScreen({super.key, required this.cameraId});

  @override
  State<CameraViewScreen> createState() => _CameraViewScreenState();
}

class _CameraViewScreenState extends State<CameraViewScreen> {
  String? _streamUrl;
  bool _isLoadingStream = true;
  String? _streamError;

  @override
  void initState() {
    super.initState();
    _loadStreamUrl();
  }

  Future<void> _loadStreamUrl() async {
    try {
      final provider = context.read<CameraProvider>();
      final url = await provider.getStreamUrl(widget.cameraId);
      if (mounted) {
        setState(() {
          _streamUrl = url;
          _isLoadingStream = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _streamError = e.toString().replaceFirst('ApiException: ', '');
          _isLoadingStream = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final camera = context.watch<CameraProvider>().getCameraById(widget.cameraId);

    return Scaffold(
      appBar: AppBar(
        title: Text(camera?.name ?? 'Camera ${widget.cameraId}'),
        actions: [
          if (camera != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                final provider = context.read<CameraProvider>();
                switch (value) {
                  case 'detection':
                    await provider.toggleDetection(widget.cameraId, !camera.isDetecting);
                  case 'recording':
                    await provider.toggleRecording(widget.cameraId, !camera.isRecording);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'detection',
                  child: Row(
                    children: [
                      Icon(
                        camera.isDetecting ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: camera.isDetecting ? AppTheme.primary : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(camera.isDetecting ? 'Disable Detection' : 'Enable Detection'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'recording',
                  child: Row(
                    children: [
                      Icon(
                        camera.isRecording ? Icons.fiber_manual_record : Icons.radio_button_off,
                        size: 20,
                        color: camera.isRecording ? AppTheme.alertCritical : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Text(camera.isRecording ? 'Stop Recording' : 'Start Recording'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(camera),
    );
  }

  Widget _buildBody(camera) {
    if (_isLoadingStream) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (_streamError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stream, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Unable to load stream',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _streamError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _loadStreamUrl,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            child: _streamUrl != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'Stream URL received',
                          style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'HLS/WebRTC player will render here',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
        if (camera != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.surfaceVariant,
            child: Row(
              children: [
                _buildStatusBadge(camera.status.name),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      camera.location ?? 'No location set',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _buildIndicator('Detection', camera.isDetecting),
                        const SizedBox(width: 16),
                        _buildIndicator('Recording', camera.isRecording),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = switch (status) {
      'online' => AppTheme.online,
      'offline' => AppTheme.offline,
      'error' => AppTheme.error,
      _ => AppTheme.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildIndicator(String label, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppTheme.online : AppTheme.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
