import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_app/models/user.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:calendar_app/services/websocket_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  DateTime? _expiryDate;
  final ApiService? _apiService;
  final WebSocketService? _webSocketService;
  String? _companyId;

 AuthProvider(this._apiService, this._webSocketService, {AuthProvider? previousAuthProvider}) {
    if (previousAuthProvider != null) {
      _token = previousAuthProvider._token;
      _user = previousAuthProvider._user;
    }
  }

  bool get isAuth => token != null;
  bool get isCompanyOwner => _user?.userType == 'CompanyOwner';
  String? get token => _token;
  User? get user => _user;
  String? get companyId => _companyId;

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService!.login(email, password);
      _token = response['token'];
      _user = User.fromJson(response['user']);
      _expiryDate = DateTime.parse(response['expiresAt']);

      if (_token != null && _user != null) {
        if (!_user!.isCompanyOwner) {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
          // JWT claims can be case-sensitive, check for common variations
          _companyId = decodedToken['CompanyId'] ?? decodedToken['companyId'];
        } else {
          _companyId = null; // Ensure companyId is null for company owners
        }
      } else {
        _companyId = null; // Reset if token or user is null
      }

      _apiService!.setToken(_token!);
      await _saveAuthData();

      // Connect WebSocket if token is available and service is initialized
      if (_token != null && _webSocketService != null) {
        await _webSocketService!.connect(_token!);
      }

      notifyListeners();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> registerCompanyOwner(
      String firstName, String lastName, String email, String password) async {
    try {
      // Registration itself doesn't return a token in your current API design,
      // so we log in immediately after to get the token and user info.
      await _apiService!.registerCompanyOwner(firstName, lastName, email, password);
      // The login method will handle token saving, user parsing, and WebSocket connection.
      await login(email, password); 
      // notifyListeners() is called within login()
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
      await logout(); // Logout will also handle WebSocket disconnection
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
    
    // Connect WebSocket if token is available and service is initialized
    if (_token != null && _webSocketService != null) {
      await _webSocketService!.connect(_token!);
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    // Disconnect WebSocket before clearing auth data
    if (_webSocketService != null) {
      _webSocketService!.disconnect();
    }

    _token = null;
    _user = null;
    _expiryDate = null;
    _companyId = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('authData');
    
    _apiService!.setToken(''); // Clear token in ApiService
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = json.encode({
      'token': _token,
      'user': _user!.toJson(), // Assuming _user is not null when this is called
      'expiryDate': _expiryDate!.toIso8601String(), // Assuming _expiryDate is not null
      'companyId': _companyId,
    });
    
    prefs.setString('authData', authData);
  }
}
