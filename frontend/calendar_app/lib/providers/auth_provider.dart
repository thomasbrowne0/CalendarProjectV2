import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_app/models/user.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../main.dart';
import '../services/websocket_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  DateTime? _expiryDate;
  final ApiService? _apiService;
  String? _companyId;

  AuthProvider(this._apiService);

  bool get isAuth => token != null;
  bool get isCompanyOwner => _user?.userType == 'CompanyOwner';
  String? get token => _token;
  User? get user => _user;
  String? get companyId => _companyId;

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService!.login(email, password);
      _token = response['token'];

      if (_token == null) {
        throw Exception('No token received from server');
      }
      _user = User.fromJson(response['user']);
      _expiryDate = DateTime.parse(response['expiresAt']);

      if (_token != null && _user != null) {
        if (!_user!.isCompanyOwner) {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
          _companyId = decodedToken['CompanyId'] ?? decodedToken['companyId'];
        } else {
          _companyId = null;
        }
      } else {
        _companyId = null;
      }

      _apiService!.setToken(_token!);
      await _saveAuthData();

      // Add retry logic for WebSocket connection
      if (_token != null) {
        await _connectWebSocket();
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }
  // New method to handle WebSocket connection with retry

  Future<void> _connectWebSocket() async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        final wsService = Provider.of<WebSocketService>(
          navigatorKey.currentContext!,
          listen: false,
        );

        // Ensure token is properly formatted
        await wsService.connect(_token!);
        break;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          print('Failed to connect to WebSocket after $maxRetries attempts');
          rethrow;
        }
        await Future.delayed(Duration(seconds: 2 * retryCount)); // Exponential backoff
      }
    }
  }

  Future<void> registerCompanyOwner(
      String firstName, String lastName, String email, String password) async {
    try {
      await _apiService!.registerCompanyOwner(firstName, lastName, email, password);
      await login(email, password);
    } catch (error) {
      rethrow;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('authData')) {
      return false;
    }

    final extractedData =
        json.decode(prefs.getString('authData')!) as Map<String, dynamic>;
    final expiryDate = DateTime.parse(extractedData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      await logout();
      return false;
    }

    _token = extractedData['token'];
    _user = User.fromJson(extractedData['user']);
    _expiryDate = expiryDate;
    _companyId = extractedData['companyId'];

    // Fallback: If companyId wasn't in prefs (e.g., older session data), try decoding token
    if (_companyId == null && _token != null && _user != null && !_user!.isCompanyOwner) {
      Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      _companyId = decodedToken['CompanyId'] ?? decodedToken['companyId'];
    } else if (_user != null && _user!.isCompanyOwner) {
      _companyId = null; // Ensure companyId is null for company owners
    }

    _apiService!.setToken(_token!);
    
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    Provider.of<WebSocketService>(navigatorKey.currentContext!, listen: false)
        .disconnect();
    _token = null;
    _user = null;
    _expiryDate = null;
    _companyId = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('authData');
    
    _apiService!.setToken('');
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = json.encode({
      'token': _token,
      'user': _user!.toJson(),
      'expiryDate': _expiryDate!.toIso8601String(),
      'companyId': _companyId,
    });
    
    prefs.setString('authData', authData);
  }
}
