import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _createChannels();
    _initialized = true;
  }

  void _createChannels() {
    if (Platform.isAndroid) {
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'critical_alerts',
          'Critical Alerts',
          description: 'Blacklist matches and critical security alerts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'info_alerts',
          'Information Alerts',
          description: 'Unknown faces and general notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> showAlertNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    bool isCritical = false,
  }) async {
      final androidDetails = AndroidNotificationDetails(
        isCritical ? 'critical_alerts' : 'info_alerts',
        isCritical ? 'Critical Alerts' : 'Information Alerts',
        channelDescription: isCritical
            ? 'Blacklist matches and critical security alerts'
            : 'Unknown faces and general notifications',
        importance: isCritical ? Importance.max : Importance.defaultImportance,
        priority: isCritical ? Priority.high : Priority.defaultPriority,
        color: isCritical ? const Color(0xFFFF5252) : null,
        ledColor: isCritical ? const Color(0xFFFF5252) : null,
        ledOnMs: isCritical ? 1000 : 0,
        ledOffMs: isCritical ? 500 : 0,
        showProgress: false,
        autoCancel: true,
      );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
