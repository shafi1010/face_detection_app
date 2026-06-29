import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

class WebSocketClient {
  final String baseWsUrl;
  final Future<String?> Function() getToken;
  void Function(dynamic message) onMessage;
  void Function(WsConnectionState state)? onStateChange;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  WsConnectionState _state = WsConnectionState.disconnected;
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30;

  WsConnectionState get state => _state;

  WebSocketClient({
    required this.baseWsUrl,
    required this.getToken,
    required this.onMessage,
    this.onStateChange,
  });

  void _setState(WsConnectionState newState) {
    if (_disposed) return;
    _state = newState;
    onStateChange?.call(newState);
  }

  Future<void> connect() async {
    if (_disposed) return;
    if (_state == WsConnectionState.connecting || _state == WsConnectionState.connected) return;

    _setState(WsConnectionState.connecting);

    try {
      final token = await getToken();
      if (token == null) {
        _setState(WsConnectionState.disconnected);
        return;
      }

      final uri = Uri.parse('$baseWsUrl?token=$token');
      _channel = WebSocketChannel.connect(uri);

      await _channel!.ready;
      _reconnectAttempts = 0;
      _setState(WsConnectionState.connected);
      _startHeartbeat();

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data as String);
            onMessage(decoded);
          } catch (_) {
            onMessage(data);
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket closed');
          _scheduleReconnect();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('WebSocket connect failed: $e');
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && _state == WsConnectionState.connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == WsConnectionState.connected) {
        send({'type': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _setState(WsConnectionState.reconnecting);
    _subscription?.cancel();
    _channel?.sink.close();
    _heartbeatTimer?.cancel();

    _reconnectAttempts++;
    final delay = (_reconnectAttempts * 2).clamp(1, _maxReconnectDelay);
    debugPrint('Reconnecting in ${delay}s (attempt $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), connect);
  }

  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    await _channel?.sink.close();
    _setState(WsConnectionState.disconnected);
  }
}
