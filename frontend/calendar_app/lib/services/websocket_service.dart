import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart' if (dart.library.io) 'package:web_socket_channel/io.dart';
import 'package:calendar_app/services/api_service.dart';

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
      final cleanToken = token.replaceAll('Bearer ', '');
      final wsUrl = Uri.parse('ws://localhost:5188/ws?token=$cleanToken');

      _channel = WebSocketChannel.connect(wsUrl);

      _isConnected = true;

      _channel!.stream.listen(
            (message) {
          if (message is String) {
            try {
              final decodedMessage = jsonDecode(message);
              _messageController.add(decodedMessage);
            } catch (e) {
              print('Error decoding message: $e');
            }
          }
        },
        onDone: () {
          print('WebSocket connection closed.');
          _isConnected = false;
          disconnect();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
      rethrow;
    }
  }


  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      print('Cannot send message: WebSocket not connected');
      return;
    }

    try {
      final message = jsonEncode({
        'type': type,
        'data': data,
      });
      _channel!.sink.add(message);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}