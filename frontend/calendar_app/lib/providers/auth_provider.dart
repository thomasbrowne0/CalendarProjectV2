import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calendar_app/models/user.dart';
import 'package:calendar_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _token;
  DateTime? _expiryDate;
  final ApiService? _apiService;

  AuthProvider(this._apiService);

  bool get isAuth => token != null;
  bool get isCompanyOwner => _user?.userType == 'CompanyOwner';
  String? get token => _token;
  User? get user => _user;

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService!.login(email, password);
      _token = response['token'];
      _user = User.fromJson(response['user']);
      _expiryDate = DateTime.parse(response['expiresAt']);

      _apiService!.setToken(_token!);
      _saveAuthData();
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
    final expiryDate = DateTime.parse(extractedData['expiryDate']);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }

    _token = extractedData['token'];
    _user = User.fromJson(extractedData['user']);
    _expiryDate = expiryDate;
    _apiService!.setToken(_token!);
    
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _expiryDate = null;
    
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('authData');
    
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = json.encode({
      'token': _token,
      'user': _user!.toJson(),
      'expiryDate': _expiryDate!.toIso8601String(),
    });
    
    prefs.setString('authData', authData);
  }
}
