import 'package:flutter/foundation.dart';
import 'package:calendar_app/models/company.dart';
import 'package:calendar_app/models/employee.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class CompanyProvider with ChangeNotifier {
  List<Company> _companies = [];
  Company? _selectedCompany;
  List<Employee> _employees = [];
  
  final ApiService? _apiService;
  final AuthProvider? _authProvider;

  CompanyProvider(this._apiService, this._authProvider);

  List<Company> get companies => [..._companies];
  Company? get selectedCompany => _selectedCompany;
  List<Employee> get employees => [..._employees];

  Future<void> fetchCompanies() async {
    if (!_authProvider!.isAuth) return;
    
    try {
      final companies = await _apiService!.getCompanies();
      _companies = companies;
      notifyListeners();
    } catch (error) {
      print('Error fetching companies: $error');
      throw error;
    }
  }

  Future<void> selectCompany(String companyId) async {
    _selectedCompany = _companies.firstWhere((c) => c.id == companyId);
    await fetchEmployees(companyId);
    notifyListeners();
  }

  Future<void> createCompany(String name, String cvr) async {
    try {
      final company = await _apiService!.createCompany(name, cvr);
      _companies.add(company);
      notifyListeners();
    } catch (error) {
      print('Error creating company: $error');
      throw error;
    }
  }

  Future<void> fetchEmployees(String companyId) async {
    try {
      final employees = await _apiService!.getEmployees(companyId);
      _employees = employees;
      notifyListeners();
    } catch (error) {
      print('Error fetching employees: $error');
      throw error;
    }
  }

  Future<void> addEmployee(
      String companyId, String firstName, String lastName, String email, String password, String jobTitle) async {
    try {
      final employee = await _apiService!.createEmployee(companyId, {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'jobTitle': jobTitle,
      });
      
      _employees.add(employee);
      notifyListeners();
    } catch (error) {
      print('Error adding employee: $error');
      throw error;
    }
  }
}
