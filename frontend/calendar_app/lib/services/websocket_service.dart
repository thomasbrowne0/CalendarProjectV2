import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:calendar_app/services/api_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  String? _currentSessionId;
  bool _isConnected = false;
  StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  ApiService? _apiService;
  
  WebSocketService(this._apiService);
  
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  
  bool get isConnected => _isConnected;

  Future<void> connect(String sessionId) async {
    if (_isConnected) return;
    
    _currentSessionId = sessionId;
    
    try {
      // IMPORTANT: Connect DIRECTLY to port 8181 (Fleck) - NO /ws path
      const String wsHost = 'localhost';
      const int wsPort = 8181;
      final wsUrl = Uri.parse('ws://$wsHost:$wsPort');
      print('WebSocketService: Connecting to WebSocket at $wsUrl');
      
      _channel = WebSocketChannel.connect(wsUrl);
      print('WebSocketService: Channel created successfully');
      
      try {
        await _channel!.ready;
        _isConnected = true;
        print('WebSocketService: Connection established');

        _channel!.stream.listen(
          (message) {
            print('WebSocket message received: $message');
            try {
              final Map<String, dynamic> parsedMessage = json.decode(message);
              _messageController.add(parsedMessage);
            } catch (e) {
              print('Error parsing WebSocket message: $e');
            }
          },
          onDone: () {
            print('WebSocket connection closed');
            _isConnected = false;
          },
          onError: (error) {
            print('WebSocket Error: $error');
            _isConnected = false;
          },
        );

        _sendSessionMessage(sessionId);
      } catch (connectError) {
        print('WebSocketService: Error establishing connection: $connectError');
        _isConnected = false;
      }
    } catch (e) {
      print('WebSocketService: Error creating channel: $e');
      _isConnected = false;
    }
  }

  void _sendSessionMessage(String sessionId) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'session',
      'sessionId': sessionId
    };
    
    print('Sent session message to WebSocket server');
    _channel!.sink.add(json.encode(message));
  }

  void setCompany(String companyId) {
    if (!_isConnected || _channel == null) return;
    
    final message = {
      'type': 'setcompany', // Fixed: use lowercase to match server's expectations
      'data': {
        'companyId': companyId
      }
    };
    
    _channel!.sink.add(json.encode(message));
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close();
      _isConnected = false;
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}