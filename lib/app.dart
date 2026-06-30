import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/network/websocket_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/alert_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/camera_provider.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/camera_service.dart';
import 'services/notification_service.dart';

class FaceWatchApp extends StatefulWidget {
  final AuthService authService;
  final CameraService cameraService;
  final AlertService alertService;
  final NotificationService notificationService;
  final WebSocketClient wsClient;

  const FaceWatchApp({
    super.key,
    required this.authService,
    required this.cameraService,
    required this.alertService,
    required this.notificationService,
    required this.wsClient,
  });

  @override
  State<FaceWatchApp> createState() => _FaceWatchAppState();
}

class _FaceWatchAppState extends State<FaceWatchApp> {
  late final AuthProvider _authProvider;
  late final CameraProvider _cameraProvider;
  late final AlertProvider _alertProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _authProvider = AuthProvider(authService: widget.authService);
    _cameraProvider = CameraProvider(cameraService: widget.cameraService);
    _alertProvider = AlertProvider(
      alertService: widget.alertService,
      wsClient: widget.wsClient,
    );

    _router = AppRouter.create(_authProvider);
  }

  @override
  void dispose() {
    widget.wsClient.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _cameraProvider),
        ChangeNotifierProvider.value(value: _alertProvider),
      ],
      child: MaterialApp.router(
        title: 'FaceWatch',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routerConfig: _router,
      ),
    );
  }
}
