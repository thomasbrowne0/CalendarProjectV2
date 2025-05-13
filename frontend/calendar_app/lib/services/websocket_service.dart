import 'dart:async';
import 'dart:convert';
import 'package:calendar_app/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final ApiService _apiService;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  bool _isConnected = false;

  WebSocketService(this._apiService);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected) return;

    try {
      final wsUrl = Uri.parse('ws://localhost:5188/ws?token=$token');
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;

      _channel!.stream.listen(
        (message) {
          final decodedMessage = jsonDecode(message);
          _messageController.add(decodedMessage);
        },
        onDone: () {
          _isConnected = false;
          // Attempt reconnect after a delay
          Future.delayed(const Duration(seconds: 5), () => connect(token));
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
    }
  }

  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message: WebSocket not connected');
      return;
    }

    final message = jsonEncode({
      'type': type,
      'data': data,
    });
    _channel!.sink.add(message);
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
