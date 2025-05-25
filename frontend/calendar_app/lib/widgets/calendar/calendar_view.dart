import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:calendar_app/cubit/calendar_state.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/services/company_calendar_service.dart';
import 'package:provider/provider.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  final CompanyCalendarService _calendarService = CompanyCalendarService();

  @override
  Widget build(BuildContext context) {
    final companyId = Provider.of<CompanyProvider>(context).selectedCompany!.id;

    return Column(
      children: [
        _buildFormatSelector(),
        _buildCalendar(companyId),
      ],
    );
  }

  Widget _buildFormatSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _calendarService.getFormatTitle(_calendarFormat),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: _changeCalendarFormat,
            child: const Text('Change View'),
          )
        ],
      ),
    );
  }

  void _changeCalendarFormat() {
    setState(() {
      if (_calendarFormat == CalendarFormat.month) {
        _calendarFormat = CalendarFormat.twoWeeks;
      } else if (_calendarFormat == CalendarFormat.twoWeeks) {
        _calendarFormat = CalendarFormat.week;
      } else {
        _calendarFormat = CalendarFormat.month;
      }
    });
  }

  Widget _buildCalendar(String companyId) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      buildWhen: (previous, current) =>
          previous.focusedDay != current.focusedDay ||
          previous.events != current.events,
      builder: (context, state) {
        return TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: state.focusedDay,
          calendarFormat: _calendarFormat,
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
          calendarStyle: _buildCalendarStyle(context),
          daysOfWeekStyle: _buildDaysOfWeekStyle(context),
          eventLoader: (day) => context.read<CalendarCubit>().getEventsForDay(day),
          selectedDayPredicate: (day) =>
              _calendarService.isSameDay(state.focusedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            context.read<CalendarCubit>().setFocusedDay(focusedDay);
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            _onPageChanged(focusedDay, companyId);
          },
        );
      },
    );
  }

  CalendarStyle _buildCalendarStyle(BuildContext context) {
    return CalendarStyle(
      markersMaxCount: 3,
      markerDecoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFFFF4081)  // Pink in dark mode
          : Theme.of(context).colorScheme.onBackground,  // Black in light mode
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
    );
  }

  DaysOfWeekStyle _buildDaysOfWeekStyle(BuildContext context) {
    return DaysOfWeekStyle(
      weekdayStyle: TextStyle(
        color: Theme.of(context).colorScheme.onBackground,
        fontWeight: FontWeight.bold,
      ),
      weekendStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void _onPageChanged(DateTime focusedDay, String companyId) {
    context.read<CalendarCubit>().setFocusedDay(focusedDay);
    context.read<CalendarCubit>().fetchEvents(
      companyId,
      start: DateTime(focusedDay.year, focusedDay.month, 1),
      end: DateTime(focusedDay.year, focusedDay.month + 1, 0),
    );
  }
}
