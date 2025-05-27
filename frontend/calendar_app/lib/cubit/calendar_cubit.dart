import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';
import 'package:logging/logging.dart';

import 'calendar_state.dart';

/// Logger for debugging and error tracking
final _logger = Logger('CalendarCubit');

/// CalendarCubit manages calendar-related logic and state using BLoC (Cubit).
/// It listens to WebSocket messages, fetches/upserts/deletes events from the API,
/// and emits new states accordingly.
class CalendarCubit extends Cubit<CalendarState> {
  final ApiService _apiService;
  final WebSocketService _webSocketService;

  StreamSubscription? _webSocketSubscription;
  String? companyId;

  /// Initializes the cubit with API and WebSocket services and sets up the listener.
  CalendarCubit(this._apiService, this._webSocketService)
      : super(CalendarState(focusedDay: DateTime.now())) {
    _setupWebSocketListener();
  }

  /// Manually sets the company ID (used to fetch/update events).
  void setCompanyId(String id) {
    companyId = id;
    _logger.info('CalendarCubit: Company ID set to $id');
  }

  /// Listens for WebSocket messages and handles different event types.
  void _setupWebSocketListener() {
    _webSocketSubscription = _webSocketService.messageStream.listen((message) {
      _logger.info('CalendarCubit received message: ${message['Type']}');

      if (message['Type'] == 'CompanySet' && message['CompanyId'] != null) {
        setCompanyId(message['CompanyId']);

      } else if (message['Type'] == 'EventCreated') {
        _handleEventCreated(message['Data']['EventId']);

      } else if (message['Type'] == 'EventUpdated') {
        _handleEventUpdated(message['Data']['EventId']);

      } else if (message['Type'] == 'EventDeleted') {
        _handleEventDeleted(message['Data']['EventId']);
      }
    });
  }

  /// Handles newly created events.
  /// Fetches full event data from the API and updates the state.
  void _handleEventCreated(String eventId) async {
    if (companyId == null) {
      _logger.severe('CalendarCubit: Company ID is null, cannot fetch event. Using AuthProvider instead.');
      if (_apiService.companyId != null) {
        companyId = _apiService.companyId;
      } else {
        _logger.severe('CalendarCubit: Both local and ApiService companyId are null. Cannot fetch event.');
        return;
      }
    }

    try {
      final event = await _apiService.getEventById(companyId!, eventId);
      final updatedEvents = [...state.events, event];
      emit(state.copyWith(events: updatedEvents));

    } catch (e) {
      _logger.severe('CalendarCubit: Error handling EventCreated: $e');

      try {
        // Fallback: refetch all events
        final startDate = DateTime(state.focusedDay.year, state.focusedDay.month, 1);
        final endDate = DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0);

        final events = await _apiService.getEvents(companyId!, startDate, endDate);
        emit(state.copyWith(events: events));
      } catch (fallbackError) {
        _logger.severe('CalendarCubit: Fallback refresh also failed: $fallbackError');
      }
    }
  }

  /// Updates an existing event in the state by refetching its details from the API.
  void _handleEventUpdated(String eventId) async {
    if (companyId == null) {
      if (_apiService.companyId != null) {
        companyId = _apiService.companyId;
      } else {
        return;
      }
    }

    try {
      final updatedEvent = await _apiService.getEventById(companyId!, eventId);
      final index = state.events.indexWhere((e) => e.id == eventId);
      final updatedEvents = [...state.events];

      if (index >= 0) {
        updatedEvents[index] = updatedEvent;
      } else {
        updatedEvents.add(updatedEvent);
      }

      emit(state.copyWith(events: updatedEvents));

    } catch (e) {
      _logger.severe('CalendarCubit: Error handling EventUpdated: $e');
    }
  }

  /// Removes the deleted event from the state.
  void _handleEventDeleted(String eventId) {
    final updatedEvents = state.events.where((e) => e.id != eventId).toList();
    emit(state.copyWith(events: updatedEvents));
  }

  /// Sets the currently focused day on the calendar.
  void setFocusedDay(DateTime day) {
    emit(state.copyWith(focusedDay: day));
  }

  /// Fetches events for a company between `start` and `end` date (default is current month).
  Future<void> fetchEvents(String companyId, {DateTime? start, DateTime? end}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final startDate = start ?? DateTime(state.focusedDay.year, state.focusedDay.month, 1);
      final endDate = end ?? DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0);

      final events = await _apiService.getEvents(companyId, startDate, endDate);
      emit(state.copyWith(events: events, isLoading: false));

    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Returns a list of events that occur on a specific day.
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.events.where((event) {
      return isSameDay(event.startTime, day) ||
          isSameDay(event.endTime, day) ||
          (event.startTime.isBefore(day) && event.endTime.isAfter(day));
    }).toList();
  }

  /// Utility function to check if two dates are on the same calendar day.
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Sends updated event details to the API.
  /// WebSocket message will trigger state update.
  Future<void> updateEvent(
      String eventId,
      String companyId,
      String title,
      String description,
      DateTime startTime,
      DateTime endTime,
      List<String> participantIds,
      ) async {
    try {
      await _apiService.updateEvent(companyId, eventId, {
        'title': title,
        'description': description,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'participantIds': participantIds,
      });

    } catch (error) {
      _logger.severe('CalendarCubit: Error updating event: $error');
      rethrow;
    }
  }

  /// Requests API to delete the event.
  /// WebSocket will handle updating the state.
  Future<void> deleteEvent(String companyId, String eventId) async {
    try {
      await _apiService.deleteEvent(companyId, eventId);
    } catch (error) {
      _logger.severe('CalendarCubit: Error deleting event: $error');
      rethrow;
    }
  }

  /// Cancels the WebSocket subscription when the cubit is closed.
  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    return super.close();
  }
}
