import 'dart:async';
import 'dart:convert';

import 'package:calendar_app/services/api_service.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _logger = Logger('WebSocketService');

/// A service that handles WebSocket connections and communication.
class WebSocketService {
  final ApiService _apiService;
  WebSocketChannel? _channel;
  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();

  bool _isConnected = false;
  String? _currentToken;

  WebSocketService(this._apiService);

  /// Exposes a broadcast stream for listening to WebSocket messages.
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _isConnected;

  /// Connects to the WebSocket server and authenticates.
  Future<void> connect(String token) async {
    if (_isConnected) return;

    _currentToken = token;
    final wsUrl = Uri.parse('wss://calendar-backend-503012500647.europe-north1.run.app/ws');

    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;

      _logger.info('WebSocket connected to ${wsUrl.toString()}');

      _channel!.stream.listen(
        _onMessageReceived,
        onDone: _onConnectionClosed,
        onError: _onConnectionError,
      );

      _sendAuthenticationMessage(token);
    } catch (e) {
      _logger.severe('Error connecting to WebSocket: $e');
      _isConnected = false;
    }
  }

  /// Handles incoming WebSocket messages.
  void _onMessageReceived(dynamic message) {
    _logger.info('WebSocket message received: $message');

    final decodedMessage = jsonDecode(message);

    // Handle authentication response
    if (decodedMessage['Type'] == 'AuthenticationResult') {
      if (decodedMessage['Success'] == true) {
        _logger.info('WebSocket authentication successful for user: ${decodedMessage['UserId']}');

        // Automatically associate with company after successful auth
        final companyId = _apiService.companyId;
        if (companyId != null && companyId.isNotEmpty) {
          setCompany(companyId);
        }
      } else {
        _logger.severe('WebSocket authentication failed: ${decodedMessage['Reason']}');
      }
    }

    _messageController.add(decodedMessage);
  }

  /// Handles WebSocket connection closed event.
  void _onConnectionClosed() {
    _logger.warning('WebSocket connection closed');
    _isConnected = false;

    // Try to reconnect after a short delay
    if (_currentToken != null) {
      Future.delayed(const Duration(seconds: 5), () => connect(_currentToken!));
    }
  }

  /// Handles errors from WebSocket stream.
  void _onConnectionError(dynamic error) {
    _logger.severe('WebSocket Error: $error');
    _isConnected = false;
  }

  /// Sends an authentication message to the WebSocket server.
  void _sendAuthenticationMessage(String token) {
    if (!_isConnected || _channel == null) return;

    final authMessage = {
      'type': 'authenticate',
      'token': token,
    };

    _channel!.sink.add(jsonEncode(authMessage));
    _logger.info('Sent authentication message to WebSocket server');
  }

  /// Associates the WebSocket session with a company.
  void setCompany(String companyId) {
    if (!_isConnected || _channel == null) {
      _logger.warning('Cannot set company: WebSocket not connected');
      return;
    }

    final message = {
      'type': 'setcompany',
      'data': {'companyId': companyId},
    };

    _channel!.sink.add(jsonEncode(message));
    _logger.info('Associated WebSocket connection with company: $companyId');
  }

  /// Sends a custom message through the WebSocket.
  void sendMessage(String type, Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) {
      _logger.warning('Cannot send message: WebSocket not connected');
      return;
    }

    final message = {
      'type': type,
      'data': data,
    };

    _channel!.sink.add(jsonEncode(message));
  }

  /// Disconnects the WebSocket and clears token state.
  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _currentToken = null;
  }

  /// Disposes the WebSocket and closes the message stream.
  void dispose() {
    disconnect();
    _messageController.close();
  }
}
