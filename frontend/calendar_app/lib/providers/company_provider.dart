import 'package:flutter/foundation.dart';
import 'package:calendar_app/models/company.dart';
import 'package:calendar_app/models/employee.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CompanyProvider');

class CompanyProvider with ChangeNotifier {
  List<Company> _companies = [];
  Company? _selectedCompany;
  List<Employee> _employees = [];
  
  final ApiService? _apiService;
  final AuthProvider? _authProvider;
  final WebSocketService? _webSocketService;

  CompanyProvider(this._apiService, this._authProvider, this._webSocketService);

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
      _logger.severe('Error fetching companies: $error');
      rethrow;
    }
  }

  Future<void> selectCompany(String companyId) async {
    if (_apiService == null || _authProvider == null || !_authProvider!.isAuth) {
      _logger.severe('CompanyProvider: ApiService or AuthProvider not available, or not authenticated.');
      return;
    }
    try {
      // If the selected company is already the one we want, do nothing extra unless employees need refresh.
      if (_selectedCompany?.id == companyId) {
        return;
      }

      Company? companyToSelect;

      // Try to find in existing list first
      final matchingCompaniesInList = _companies.where((c) => c.id == companyId).toList();
      if (matchingCompaniesInList.isNotEmpty) {
        companyToSelect = matchingCompaniesInList.first;
      } else {
        // If not found in the list, we need to fetch it.
        // How we fetch depends on whether the user is an owner or employee.
        if (_authProvider!.user != null && !_authProvider!.user!.isCompanyOwner) {
          // User is an EMPLOYEE, fetch their specific company by ID
          _logger.info('CompanyProvider: Employee needs company $companyId. Fetching specifically.');
          try {
            companyToSelect = await _apiService!.getCompanyById(companyId);
          } catch (e) {
            _logger.severe('CompanyProvider: Error fetching specific company $companyId for employee: $e');
            _selectedCompany = null; // Clear selection on error
            notifyListeners();
            rethrow; // Rethrow to be caught by UI
          }
        } else if (_authProvider!.user != null && _authProvider!.user!.isCompanyOwner) {
          if (_companies.isEmpty) {
            _logger.info('CompanyProvider: Owner has no companies in list. Fetching all their companies.');
             await fetchCompanies();
             final stillMatching = _companies.where((c) => c.id == companyId).toList();
             if (stillMatching.isNotEmpty) {
               companyToSelect = stillMatching.first;
             }
          } else {
            _logger.info('CompanyProvider: Owner selecting company $companyId, but it was not in the pre-loaded list of ${_companies.length} companies.');     }
        }
      }

      if (companyToSelect != null) {
        _selectedCompany = companyToSelect;
        await fetchEmployees(_selectedCompany!.id);

        if (_webSocketService != null && _webSocketService!.isConnected) {
          _webSocketService!.setCompany(companyToSelect.id);
        }
        
      } else {
        _logger.severe('CompanyProvider: Could not find or fetch company with ID: $companyId. Clearing selection.');
        _selectedCompany = null;
      }
      notifyListeners();
    } catch (error) {
      _logger.severe('CompanyProvider: General error in selectCompany for $companyId: $error');
      _selectedCompany = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createCompany(String name, String cvr) async {
    try {
      final company = await _apiService!.createCompany(name, cvr);
      _companies.add(company);
      notifyListeners();
    } catch (error) {
      _logger.severe('Error creating company: $error');
      rethrow;
    }
  }

  Future<void> fetchEmployees(String companyId) async {
    try {
      final employees = await _apiService!.getEmployees(companyId);
      _employees = employees;
      notifyListeners();
    } catch (error) {
      _logger.severe('Error fetching employees: $error');
      rethrow;
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
      _logger.severe('Error adding employee: $error');
      rethrow;
    }
  }
}
