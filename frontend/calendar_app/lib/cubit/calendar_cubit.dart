import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/services/websocket_service.dart';

import 'calendar_state.dart';


class CalendarCubit extends Cubit<CalendarState> {
  final ApiService _apiService;
  final WebSocketService _webSocketService;
  StreamSubscription? _webSocketSubscription;
  String? companyId;

  CalendarCubit(this._apiService, this._webSocketService)
      : super(CalendarState(focusedDay: DateTime.now())) {
    _setupWebSocketListener();
  }


  void setCompanyId(String id) {
    companyId = id;
    print('CalendarCubit: Company ID set to $id');
  }

  void _setupWebSocketListener() {
    _webSocketSubscription = _webSocketService.messageStream.listen((message) {
      print('CalendarCubit received message: ${message['Type']}');

      if (message['Type'] == 'CompanySet' && message['CompanyId'] != null) {
        setCompanyId(message['CompanyId']);
      }  else if (message['Type'] == 'EventCreated') {
        _handleEventCreated(message['Data']['EventId']);
      } else if (message['Type'] == 'EventUpdated') {
        _handleEventUpdated(message['Data']['EventId']);
      } else if (message['Type'] == 'EventDeleted') {
        _handleEventDeleted(message['Data']['EventId']);
      }
    });
  }

  void _handleEventCreated(String eventId) async {
    if (companyId == null) {
      print('CalendarCubit: Company ID is null, cannot fetch event. Using AuthProvider instead.');
      if (_apiService.companyId != null) {
        companyId = _apiService.companyId;
      } else {
        print('CalendarCubit: Both local and ApiService companyId are null. Cannot fetch event.');
        return;
      }
    }

    try {
      print('CalendarCubit: Fetching event with ID $eventId for company $companyId');
      final event = await _apiService.getEventById(companyId!, eventId);
      print('CalendarCubit: Successfully fetched event: ${event.title} on ${event.startTime}');

      final updatedEvents = [...state.events, event];
      print('CalendarCubit: Updating state with new event. Total events: ${updatedEvents.length}');
      emit(state.copyWith(events: updatedEvents));
    } catch (e) {
      print('CalendarCubit: Error handling EventCreated: $e');

      try {
        print('CalendarCubit: Attempting to refresh all events as fallback');
        final startDate = DateTime(state.focusedDay.year, state.focusedDay.month, 1);
        final endDate = DateTime(state.focusedDay.year, state.focusedDay.month + 1, 0);

        final events = await _apiService.getEvents(companyId!, startDate, endDate);
        emit(state.copyWith(events: events));
      } catch (fallbackError) {
        print('CalendarCubit: Fallback refresh also failed: $fallbackError');
      }
    }
  }

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
      print('CalendarCubit: Error handling EventUpdated: $e');
    }
  }

  void _handleEventDeleted(String eventId) {
    final updatedEvents = state.events.where((e) => e.id != eventId).toList();
    emit(state.copyWith(events: updatedEvents));
  }

  void setFocusedDay(DateTime day) {
    emit(state.copyWith(focusedDay: day));
  }

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

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return state.events.where((event) {
      return isSameDay(event.startTime, day) ||
             isSameDay(event.endTime, day) ||
             (event.startTime.isBefore(day) && event.endTime.isAfter(day));
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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
      // The WebSocket will handle the state update
    } catch (error) {
      print('CalendarCubit: Error updating event: $error');
      rethrow;
    }
  }

  Future<void> deleteEvent(String companyId, String eventId) async {
    try {
      await _apiService.deleteEvent(companyId, eventId);
      // The WebSocket will handle the state update
    } catch (error) {
      print('CalendarCubit: Error deleting event: $error');
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _webSocketSubscription?.cancel();
    return super.close();
  }
}