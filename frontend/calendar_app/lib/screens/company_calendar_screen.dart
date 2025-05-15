import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/screens/create_event_screen.dart';
import 'package:calendar_app/widgets/calendar_widget.dart';
import 'package:calendar_app/services/calendar_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/calendar_cubit.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CompanyCalendarScreen extends StatefulWidget {
  const CompanyCalendarScreen({super.key});

  @override
  _CompanyCalendarScreenState createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() => _isLoading = true);

      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (companyProvider.selectedCompany != null) {
        final companyId = companyProvider.selectedCompany!.id;
        Provider.of<CalendarProvider>(context, listen: false)
            .fetchEvents(companyId)
            .then((_) {
          // Load events into cubit too
          final cubit = BlocProvider.of<CalendarCubit>(context);
          cubit.loadEvents(companyId, DateTime.now());

          if (mounted) setState(() => _isLoading = false);
        }).catchError((error) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load events: ${error.toString()}')),
            );
          }
        });
      } else {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a company first')),
            );
          }
        });
      }
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return BlocProvider<CalendarCubit>(
      create: (_) => CalendarCubit(apiService, authProvider),
      child: Builder(
        builder: (context) {
          final calendarProvider = Provider.of<CalendarProvider>(context);
          final companyProvider = Provider.of<CompanyProvider>(context);
          final selectedCompany = companyProvider.selectedCompany;

          if (selectedCompany == null) {
            return CalendarWidgets.noCompanySelected(context);
          }

          final companyId = selectedCompany.id;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Company Calendar'),
              actions: [
                PopupMenuButton<String>(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          Provider.of<AuthProvider>(context).user?.fullName ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'logout') {
                      Provider.of<AuthProvider>(context, listen: false).logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Logout'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
                        CalendarService.getFormatTitle(_calendarFormat),
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
                      ),
                    ],
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: calendarProvider.focusedDay,
                  calendarFormat: _calendarFormat,
                  rangeSelectionMode: _rangeSelectionMode,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  eventLoader: (day) => calendarProvider.getEventsForDay(day),
                  selectedDayPredicate: (day) =>
                      isSameDay(calendarProvider.focusedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    calendarProvider.setFocusedDay(focusedDay);
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    calendarProvider.setFocusedDay(focusedDay);
                    calendarProvider.fetchEvents(
                      companyId,
                      start: DateTime(focusedDay.year, focusedDay.month, 1),
                      end: DateTime(focusedDay.year, focusedDay.month + 1, 0),
                    );
                  },
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 3,
                  ),
                ),
                Expanded(
                  child: CalendarWidgets.buildEventList(
                    calendarProvider.getEventsForDay(calendarProvider.focusedDay),
                    context,
                  ),
                ),
              ],
            ),
            floatingActionButton: Provider.of<AuthProvider>(context).canCreateEvents()
                ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateEventScreen(
                      selectedDate: calendarProvider.focusedDay,
                    ),
                  ),
                );
              },
              tooltip: 'Create Event',
              child: const Icon(Icons.add),
            )
                : null,
          );
        },
      ),
    );
  }
}
