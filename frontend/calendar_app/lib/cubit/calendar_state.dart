import 'package:equatable/equatable.dart';
import 'package:calendar_app/models/calendar_event.dart';

class CalendarState extends Equatable {
  final List<CalendarEvent> events;
  final DateTime focusedDay;
  final bool isLoading;
  final String? error;

  const CalendarState({
    this.events = const [],
    required this.focusedDay,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    List<CalendarEvent>? events,
    DateTime? focusedDay,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      events: events ?? this.events,
      focusedDay: focusedDay ?? this.focusedDay,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [events, focusedDay, isLoading, error];
}
