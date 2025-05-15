// lib/cubits/calendar_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/services/api_service.dart';
import 'package:calendar_app/providers/auth_provider.dart';

part 'calendar_state.dart';

class CalendarCubit extends Cubit<CalendarState> {
  final ApiService apiService;
  final AuthProvider authProvider;

  CalendarCubit(this.apiService, this.authProvider) : super(CalendarInitial());

  Future<void> loadEvents(String companyId, DateTime focusedDay) async {
    if (!authProvider.isAuth) return;

    emit(CalendarLoading());

    try {
      final events = await apiService.getEvents(
        companyId,
        DateTime(focusedDay.year, focusedDay.month, 1),
        DateTime(focusedDay.year, focusedDay.month + 1, 0),
      );
      emit(CalendarLoaded(events, focusedDay));
    } catch (e) {
      emit(CalendarError(e.toString()));
    }
  }

  void updateEvents(List<CalendarEvent> newEvents, DateTime focusedDay) {
    emit(CalendarLoaded(newEvents, focusedDay));
  }

  void addEvent(CalendarEvent event) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      final updated = List<CalendarEvent>.from(currentState.events)..add(event);
      emit(CalendarLoaded(updated, currentState.focusedDay));
    }
  }

  void setFocusedDay(DateTime newDay) {
    if (state is CalendarLoaded) {
      final currentState = state as CalendarLoaded;
      emit(CalendarLoaded(currentState.events, newDay));
    }
  }
}
