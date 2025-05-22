import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_app/models/user.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _sessionId;
  final ApiService? _apiService;
  final WebSocketService? _webSocketService;
  String? _companyId;

  AuthProvider(this._apiService, this._webSocketService, {AuthProvider? previousAuthProvider}) {
    if (previousAuthProvider != null) {
      _sessionId = previousAuthProvider._sessionId;
      _user = previousAuthProvider._user;
      _companyId = previousAuthProvider._companyId;
    }
  }

  bool get isAuth => _user != null;
  bool get isCompanyOwner => _user?.userType == 'CompanyOwner';
  User? get user => _user;
  String? get companyId => _companyId;
  String? get sessionId => _sessionId;

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService!.login(email, password);
      _user = User.fromJson(response['user']);
      _sessionId = response['sessionId'];
      
      if (_user != null && !_user!.isCompanyOwner) {
        _companyId = response['companyId']; // Get directly from response
      }

      _apiService!.setSessionId(_sessionId!);
      await _saveAuthData();

      if (_sessionId != null && _webSocketService != null) {
        await _webSocketService!.connect(_sessionId!);
      }

      notifyListeners();
    } catch (error) {
      rethrow;
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

    _user = User.fromJson(extractedData['user']);
    _sessionId = extractedData['sessionId'];
    _companyId = extractedData['companyId'];

    if (_sessionId != null) {
      _apiService!.setSessionId(_sessionId!);
      
      if (_webSocketService != null) {
        await _webSocketService!.connect(_sessionId!);
      }
    }

    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    if (_webSocketService != null) {
      _webSocketService!.disconnect();
    }

    _user = null;
    _sessionId = null;
    _companyId = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('authData');
    
    _apiService!.setSessionId(''); // Clear sessionId in ApiService
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = json.encode({
      'user': _user!.toJson(),
      'sessionId': _sessionId,
      'companyId': _companyId,
    });
    
    prefs.setString('authData', authData);
  }
}
