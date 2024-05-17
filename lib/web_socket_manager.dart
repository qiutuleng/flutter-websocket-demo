import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

typedef MessageCallback = void Function(String message);
typedef ConnectionCallback = void Function(String address);
typedef DisconnectionCallback = void Function(bool manual);
typedef ErrorCallback = void Function(String error);
typedef ReconnectingCallback = void Function();
typedef PongTimeoutCallback = void Function();

class WebSocketManager {
  final MessageCallback onMessage;
  final ConnectionCallback onConnected;
  final DisconnectionCallback onDisconnected;
  final ErrorCallback onError;
  final ReconnectingCallback onReconnecting;
  final PongTimeoutCallback onPongTimeout;

  final bool enablePing;
  final bool enablePong;

  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  bool _isManualDisconnect = false;
  bool _isReconnecting = false;
  String? _address;

  WebSocketManager({
    required this.onMessage,
    required this.onConnected,
    required this.onDisconnected,
    required this.onError,
    required this.onReconnecting,
    required this.onPongTimeout,
    this.enablePing = true,
    this.enablePong = true,
  });

  void connect(String address) {
    _address = address;
    _isManualDisconnect = false;
    _channel = IOWebSocketChannel.connect(address);
    onConnected(address);
    _channel!.stream.listen(
          (data) {
        onMessage('Received: $data');
        if (enablePong && data == 'PONG') {
          _resetPongTimeout();
        }
      },
      onDone: () {
        if (!_isManualDisconnect) {
          onDisconnected(false);
          _reconnect();
        } else {
          onDisconnected(true);
        }
      },
      onError: (error) {
        onError('Error: $error');
        _reconnect();
      },
    );
    if (enablePing) {
      _startHeartbeat();
    }
    if (enablePong) {
      _resetPongTimeout();
    }
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_channel != null) {
        _channel!.sink.add('PING');
        onMessage('Sent: PING');
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _resetPongTimeout() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = Timer(const Duration(seconds: 10), () {
      onPongTimeout();
      disconnect();
      _reconnect();
    });
  }

  void sendMessage(String message) {
    if (_channel != null) {
      _channel!.sink.add(message);
      onMessage('Sent: $message');
    }
  }

  void manualDisconnect() {
    _isManualDisconnect = true;
    disconnect();
  }

  void disconnect() {
    _stopHeartbeat();
    _channel?.sink.close();
    _channel = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  void _reconnect() {
    if (_isReconnecting) return;
    _isReconnecting = true;
    onReconnecting();
    Future.delayed(const Duration(seconds: 1), () {
      if (_address != null) {
        _isManualDisconnect = false;
        connect(_address!);
        _isReconnecting = false;
      }
    });
  }

  void dispose() {
    disconnect();
    _heartbeatTimer?.cancel();
    _pongTimeoutTimer?.cancel();
  }
}