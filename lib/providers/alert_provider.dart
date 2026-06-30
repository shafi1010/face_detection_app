import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/websocket_client.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _alertService;
  final WebSocketClient? _wsClient;

  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  int _unacknowledgedCount = 0;
  bool _wsConnected = false;

  AlertProvider({
    required AlertService alertService,
    WebSocketClient? wsClient,
  })  : _alertService = alertService,
        _wsClient = wsClient {
    _setupWebSocket();
  }

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unacknowledgedCount => _unacknowledgedCount;
  bool get wsConnected => _wsConnected;

  List<Alert> get unacknowledgedAlerts =>
      _alerts.where((a) => a.status == AlertStatus.unacknowledged).toList();

  List<Alert> get criticalAlerts =>
      _alerts.where((a) => a.severity == AlertSeverity.critical).toList();

  void _setupWebSocket() {
    _wsClient?.onStateChange = (state) {
      _wsConnected = state == WsConnectionState.connected;
      notifyListeners();
    };

    final originalOnMessage = _wsClient?.onMessage;
    if (originalOnMessage != null) {
      final wrappedOnMessage = originalOnMessage;
      _wsClient?.onMessage = (message) {
        wrappedOnMessage(message);
        _handleWsMessage(message);
      };
    }
  }

  void _handleWsMessage(dynamic message) {
    if (message is Map && message['type'] == 'alert') {
      try {
        final alert = Alert.fromJson(message['data'] as Map<String, dynamic>);
        _alerts.insert(0, alert);
        _unacknowledgedCount++;
        notifyListeners();

        _showNotification(alert);
      } catch (e) {
        debugPrint('Failed to parse WS alert: $e');
      }
    }
  }

  Future<void> _showNotification(Alert alert) async {
    final notifService = NotificationService();
    final title = switch (alert.type) {
      AlertType.blacklistMatch => 'Blacklist Match: ${alert.faceMatch?.personName ?? 'Unknown'}',
      AlertType.watchlistMatch => 'Watchlist Match: ${alert.faceMatch?.personName ?? 'Unknown'}',
      AlertType.unknownFace => 'Unknown Face Detected',
      AlertType.crowdDensity => 'Crowd Density Alert',
      AlertType.dwellTime => 'Dwell Time Alert: ${alert.cameraName}',
      AlertType.loitering => 'Loitering Detected: ${alert.cameraName}',
      AlertType.zoneViolation => 'Zone Violation: ${alert.cameraName}',
    };

    await notifService.showAlertNotification(
      id: alert.id.hashCode,
      title: title,
      body: '${alert.cameraName} — ${alert.message}',
      payload: alert.id,
      isCritical: alert.severity == AlertSeverity.critical,
    );
  }

  Future<void> fetchAlerts({bool refresh = false}) async {
    if (!refresh && _alerts.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _alertService.getAlerts();
      _unacknowledgedCount = _alerts
          .where((a) => a.status == AlertStatus.unacknowledged)
          .length;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMoreAlerts() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();

    try {
      final more = await _alertService.getAlerts(page: (_alerts.length ~/ 20) + 1);
      _alerts.addAll(more);
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> acknowledgeAlert(String id) async {
    try {
      await _alertService.acknowledgeAlert(id);
      final index = _alerts.indexWhere((a) => a.id == id);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(status: AlertStatus.acknowledged);
        _unacknowledgedCount = _alerts
            .where((a) => a.status == AlertStatus.unacknowledged)
            .length;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  Future<void> dismissAlert(String id) async {
    try {
      await _alertService.dismissAlert(id);
      _alerts.removeWhere((a) => a.id == id);
      _unacknowledgedCount = _alerts
          .where((a) => a.status == AlertStatus.unacknowledged)
          .length;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
