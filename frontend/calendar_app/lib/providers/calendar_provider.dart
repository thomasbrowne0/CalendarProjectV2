import 'package:flutter/foundation.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/providers/auth_provider.dart';

class CalendarProvider with ChangeNotifier {
  List<CalendarEvent> _events = [];
  DateTime _focusedDay = DateTime.now();
  
  final ApiService? _apiService;
  final AuthProvider? _authProvider;

  CalendarProvider(this._apiService, this._authProvider);

  List<CalendarEvent> get events => [..._events];
  DateTime get focusedDay => _focusedDay;

  void setFocusedDay(DateTime date) {
    _focusedDay = date;
    notifyListeners();
  }

  Future<void> fetchEvents(String companyId, {DateTime? start, DateTime? end}) async {
    if (!_authProvider!.isAuth) return;
    
    try {
      final startDate = start ?? DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = end ?? DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final events = await _apiService!.getEvents(companyId, startDate, endDate);
      _events = events;
      notifyListeners();
    } catch (error) {
      print('Error fetching events: $error');
      // Set events to empty list instead of throwing
      _events = [];
      notifyListeners();
      // Optionally rethrow if you want the UI to handle it
      // throw error;
    }
  }

  Future<CalendarEvent> createEvent(
      String companyId,
      String title,
      String description,
      DateTime startTime,
      DateTime endTime,
      List<String> participantIds,
      ) async {
    try {
      final event = await _apiService!.createEvent(companyId, {
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'participantIds': participantIds,
      });

      _events.add(event);
      notifyListeners();

      return event;  // <-- Return the created event
    } catch (error) {
      print('Error creating event: $error');
      rethrow;
    }
  }


  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList();
  }
}
