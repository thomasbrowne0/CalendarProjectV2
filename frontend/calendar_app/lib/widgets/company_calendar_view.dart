import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../cubit/calendar_cubit.dart';
import '../cubit/calendar_state.dart';
import '../services/company_calendar_service.dart';

class CompanyCalendarView extends StatefulWidget {
  final String companyId;
  final CalendarFormat calendarFormat;
  final Function(CalendarFormat) onFormatChanged;

  const CompanyCalendarView({
    super.key,
    required this.companyId,
    required this.calendarFormat,
    required this.onFormatChanged,
  });

  @override
  State<CompanyCalendarView> createState() => _CompanyCalendarViewState();
}

class _CompanyCalendarViewState extends State<CompanyCalendarView> {
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  final CompanyCalendarService _calendarService = CompanyCalendarService();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      buildWhen: (previous, current) =>
          previous.focusedDay != current.focusedDay ||
          previous.events != current.events,
      builder: (context, state) {
        return TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: state.focusedDay,
          calendarFormat: widget.calendarFormat,
          rangeSelectionMode: _rangeSelectionMode,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, size: 28),
            rightChevronIcon: Icon(Icons.chevron_right, size: 28),
          ),
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFFFF4081)
                : Theme.of(context).colorScheme.onBackground,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            weekendTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
            outsideTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: Theme.of(context).colorScheme.onBackground,
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          eventLoader: (day) => context.read<CalendarCubit>().getEventsForDay(day),
          selectedDayPredicate: (day) =>
              _calendarService.isSameDay(state.focusedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            context.read<CalendarCubit>().setFocusedDay(focusedDay);
          },
          onFormatChanged: widget.onFormatChanged,
          onPageChanged: (focusedDay) {
            context.read<CalendarCubit>().setFocusedDay(focusedDay);
            context.read<CalendarCubit>().fetchEvents(
              widget.companyId,
              start: DateTime(focusedDay.year, focusedDay.month, 1),
              end: DateTime(focusedDay.year, focusedDay.month + 1, 0),
            );
          },
        );
      },
    );
  }
}
