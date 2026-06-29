import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/network/websocket_client.dart';
import 'core/storage/secure_storage.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/camera_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final secureStorage = SecureStorage();
  final baseUrl = (await secureStorage.getBaseUrl()) ?? 'https://api.facewatch.io/v1';

  final apiClient = ApiClient(
    baseUrl: baseUrl,
    getToken: () => secureStorage.getToken(),
    onUnauthorized: () {},
  );

  final authService = AuthService(apiClient: apiClient, storage: secureStorage);
  final cameraService = CameraService(apiClient: apiClient);
  final alertService = AlertService(apiClient: apiClient);
  final notificationService = NotificationService();

  await notificationService.initialize();

  final wsClient = WebSocketClient(
    baseWsUrl: baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://'),
    getToken: () => secureStorage.getToken(),
    onMessage: (_) {},
  );

  runApp(
    FaceWatchApp(
      authService: authService,
      cameraService: cameraService,
      alertService: alertService,
      notificationService: notificationService,
      wsClient: wsClient,
    ),
  );
}
