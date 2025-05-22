import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:calendar_app/models/company.dart';
import 'package:calendar_app/models/employee.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ApiService');

class ApiService {
  static const String baseUrl = 'https://calendar-backend-503012500647.europe-north1.run.app/api';
  String? _token;
  String? _companyId;

  String? get token => _token;

  String? get companyId => _companyId;

  void setToken(String token) {
    _token = token;
  }

  void setCompanyContext(String companyId) {
    _companyId = companyId;
    _logger.info('Company context set to: $companyId');
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<Map<String, dynamic>> registerCompanyOwner(
      String firstName, String lastName, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-company-owner'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register');
    }
  }

  // Companies
  Future<List<Company>> getCompanies() async {
    final response = await http.get(
      Uri.parse('$baseUrl/companies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Company.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load companies');
    }
  }

  Future<Company> createCompany(String name, String cvr) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companies'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'cvr': cvr,
      }),
    );

    if (response.statusCode == 201) {
      return Company.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create company');
    }
  }

  Future<Company> getCompanyById(String companyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/companies/$companyId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Company.fromJson(jsonDecode(response.body));
    } else {
      _logger.severe(
          'ApiService: Failed to load company $companyId. Status: ${response.statusCode}, Body: ${response.body}');
      throw Exception('Failed to load company details for $companyId');
    }
  }

  // Employees
  Future<List<Employee>> getEmployees(String companyId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/companies/$companyId/employees'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Employee.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load employees');
    }
  }

  Future<Employee> createEmployee(
      String companyId, Map<String, dynamic> employee) async {
    final response = await http.post(
      Uri.parse('$baseUrl/companies/$companyId/employees'),
      headers: _headers,
      body: jsonEncode(employee),
    );

    if (response.statusCode == 201) {
      return Employee.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create employee');
    }
  }

  // Calendar Events
  Future<List<CalendarEvent>> getEvents(
      String companyId, DateTime start, DateTime end) async {
    try {
      // Format dates as ISO strings without milliseconds for better compatibility
      String startParam = '${start.toUtc().toIso8601String().split('.')[0]}Z';
      String endParam = '${end.toUtc().toIso8601String().split('.')[0]}Z';

      final response = await http.get(
        Uri.parse(
            '$baseUrl/companies/$companyId/events?start=$startParam&end=$endParam'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // Handle empty response
        if (response.body.isEmpty) {
          return [];
        }

        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        _logger.severe(
            "Error fetching events. Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to load events (${response.statusCode})');
      }
    } catch (e) {
      _logger.severe("Error fetching events: $e");
      throw Exception('Failed to load events');
    }
  }

  Future<CalendarEvent> getEventById(String companyId, String eventId) async {
    _logger.info('ApiService: Fetching event $eventId for company $companyId');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/companies/$companyId/events/$eventId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final event = CalendarEvent.fromJson(jsonDecode(response.body));
        _logger.info('ApiService: Successfully fetched event ${event.title}');
        return event;
      } else {
        _logger.severe(
            'ApiService: Failed to fetch event, status: ${response.statusCode}, body: ${response.body}');
        throw Exception('Failed to load event (${response.statusCode})');
      }
    } catch (e) {
      _logger.severe('ApiService: Error fetching event: $e');
      throw Exception('Failed to load event: $e');
    }
  }

  Future<CalendarEvent> createEvent(
      String companyId, Map<String, dynamic> event) async {
    try {
      // Ensure dates are in UTC format without milliseconds
      if (event['startTime'] is DateTime) {
        event['startTime'] =
            '${(event['startTime'] as DateTime).toUtc().toIso8601String().split('.')[0]}Z';
      }

      if (event['endTime'] is DateTime) {
        event['endTime'] =
            '${(event['endTime'] as DateTime).toUtc().toIso8601String().split('.')[0]}Z';
      }

      // Ensure participantIds is an array of strings (not objects)
      if (event['participantIds'] != null && event['participantIds'] is List) {
        List<String> participantIds = (event['participantIds'] as List)
            .map((id) => id.toString())
            .toList();
        event['participantIds'] = participantIds;
      }

      _logger.info("Event data being sent: ${jsonEncode(event)}");

      final response = await http.post(
        Uri.parse('$baseUrl/companies/$companyId/events'),
        headers: _headers,
        body: jsonEncode(event),
      );

      if (response.statusCode == 201) {
        return CalendarEvent.fromJson(jsonDecode(response.body));
      } else {
        _logger.severe(
            "Error creating event. Status: ${response.statusCode}, Body: ${response.body}");
        throw Exception('Failed to create event (${response.statusCode})');
      }
    } catch (e) {
      _logger.severe("Error creating event: $e");
      throw Exception('Failed to create event');
    }
  }

  Future<void> updateEvent(
      String companyId, String eventId, Map<String, dynamic> eventData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/companies/$companyId/events/$eventId'),
      headers: _headers,
      body: jsonEncode(eventData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update event');
    }
  }

  Future<void> deleteEvent(String companyId, String eventId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/companies/$companyId/events/$eventId'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }
}
