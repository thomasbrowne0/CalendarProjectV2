import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/screens/create_event_screen.dart';
import 'package:calendar_app/services/company_calendar_service.dart';
import 'package:calendar_app/widgets/calendar_widgets.dart';
import '../cubit/calendar_cubit.dart';
import '../cubit/calendar_state.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  State<CompanyCalendarScreen> createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  final CompanyCalendarService _calendarService = CompanyCalendarService();

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      if (companyProvider.selectedCompany != null) {
        final companyId = companyProvider.selectedCompany!.id;

        context.read<CalendarCubit>().setCompanyId(companyId);
        context.read<CalendarCubit>().fetchEvents(companyId).then((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load events: ${error.toString()}')),
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final companyProvider = Provider.of<CompanyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final selectedCompany = companyProvider.selectedCompany;
    final isCompanyOwner = authProvider.user?.userType == 'CompanyOwner';

    if (selectedCompany == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Company Calendar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: CalendarWidgets.noCompanySelectedWidget(context),
      );
    }

    final companyId = selectedCompany.id;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _calendarService.getFormatTitle(_calendarFormat),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_calendarFormat == CalendarFormat.month) {
                        _calendarFormat = CalendarFormat.twoWeeks;
                      } else if (_calendarFormat == CalendarFormat.twoWeeks) {
                        _calendarFormat = CalendarFormat.week;
                      } else {
                        _calendarFormat = CalendarFormat.month;
                      }
                    });
                  },
                  child: const Text('Change View'),
                )
              ],
            ),
          ),
          BlocBuilder<CalendarCubit, CalendarState>(
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
                calendarStyle: CalendarStyle(
                  markersMaxCount: 3,
                  markerDecoration: const BoxDecoration(
                    color: Color(0xFFFF4081),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
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
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  context.read<CalendarCubit>().setFocusedDay(focusedDay);
                  context.read<CalendarCubit>().fetchEvents(
                    companyId,
                    start: DateTime(focusedDay.year, focusedDay.month, 1),
                    end: DateTime(focusedDay.year, focusedDay.month + 1, 0),
                  );
                },
              );
            },
          ),
          Expanded(
            child: BlocBuilder<CalendarCubit, CalendarState>(
              buildWhen: (previous, current) =>
              previous.events != current.events ||
                  previous.focusedDay != current.focusedDay,
              builder: (context, state) {
                final events =
                context.read<CalendarCubit>().getEventsForDay(state.focusedDay);

                if (events.isEmpty) {
                  return const Center(
                    child: Text('No events for this day.'),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (ctx, index) =>
                      CalendarWidgets.buildEventCard(events[index], context),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: isCompanyOwner
          ? FloatingActionButton(
        onPressed: () {
          final focusedDate = context.read<CalendarCubit>().state.focusedDay;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateEventScreen(selectedDate: focusedDate),
            ),
          );
        },
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}
