// lib/cubits/calendar_state.dart
part of 'calendar_cubit.dart';

abstract class CalendarState {}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarLoaded extends CalendarState {
  final List<CalendarEvent> events;
  final DateTime focusedDay;

  CalendarLoaded(this.events, this.focusedDay);
}

class CalendarError extends CalendarState {
  final String message;

  CalendarError(this.message);
}
