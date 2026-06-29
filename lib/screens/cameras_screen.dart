import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/camera_provider.dart';
import '../widgets/camera_card.dart';

class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CameraProvider>().fetchCameras();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CameraProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Cameras (${provider.onlineCount}/${provider.cameras.length})'),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchCameras(refresh: true),
        color: AppTheme.primary,
        child: _buildBody(provider),
      ),
    );
  }

  Widget _buildBody(CameraProvider provider) {
    if (provider.isLoading && provider.cameras.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (provider.error != null && provider.cameras.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                provider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => provider.fetchCameras(refresh: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.cameras.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 48, color: AppTheme.textMuted),
            SizedBox(height: 16),
            Text(
              'No cameras configured',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            SizedBox(height: 8),
            Text(
              'Add cameras from the web dashboard',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: provider.cameras.length,
      itemBuilder: (_, index) {
        final camera = provider.cameras[index];
        return CameraCard(
          camera: camera,
          onTap: () => context.go('/cameras/${camera.id}'),
        );
      },
    );
  }
}
