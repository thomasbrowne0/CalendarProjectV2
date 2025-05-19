import 'dart:async';
import 'dart:convert';
import 'package:calendar_app/services/api_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final ApiService _apiService;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  bool _isConnected = false;
  String? _currentToken;

  WebSocketService(this._apiService);

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    if (_isConnected) return;
    _currentToken = token;

    try {
      final wsUrl = Uri.parse('ws://localhost:8181');
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      
      print('WebSocket connected to ${wsUrl.toString()}');

      _channel!.stream.listen(
        (message) {
          print('WebSocket message received: $message');
          final decodedMessage = jsonDecode(message);

          if (decodedMessage['Type'] == 'AuthenticationResult') {
            if (decodedMessage['Success'] == true) {
              print('WebSocket authentication successful for user: ${decodedMessage['UserId']}');
              if (_apiService.companyId != null && _apiService.companyId!.isNotEmpty) {
                setCompany(_apiService.companyId!);
              }
            } else {
              print('WebSocket authentication failed: ${decodedMessage['Reason']}');
            }
          }
          
          _messageController.add(decodedMessage);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          Future.delayed(const Duration(seconds: 5), () => connect(_currentToken!));
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _isConnected = false;
        },
      );

      _sendAuthenticationMessage(token);
    } catch (e) {
      print('Error connecting to WebSocket: $e');
      _isConnected = false;
    }
  }

  void _sendAuthenticationMessage(String token) {
    if (!_isConnected || _channel == null) return;
    
    final authMessage = {
      'type': 'authenticate',
      'token': token
    };
    
    _channel!.sink.add(jsonEncode(authMessage));
    print('Sent authentication message to WebSocket server');
  }

  void setCompany(String companyId) {
    if (!_isConnected || _channel == null) {
      print('Cannot set company: WebSocket not connected');
      return;
    }
    
    final message = {
      'type': 'setcompany',
      'data': {
        'companyId': companyId
      }
    };
    
    _channel!.sink.add(jsonEncode(message));
    print('Associated WebSocket connection with company: $companyId');
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
    _currentToken = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}