import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/screens/create_event_screen.dart';
import 'package:calendar_app/screens/event_details_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/blocs/calendar_cubit.dart';

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
    setState(() {
      _isLoading = true;
    });
    
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    if (companyProvider.selectedCompany != null) {
      final companyId = companyProvider.selectedCompany!.id;
      
      // Set company ID in CalendarCubit
      context.read<CalendarCubit>().setCompanyId(companyId);
      
      // Use Cubit to fetch events
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
    final selectedCompany = companyProvider.selectedCompany;
    
    // If no company is selected, show a message
    if (selectedCompany == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Company Calendar'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No company selected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Please select a company to view its calendar'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to company selection
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    final companyId = selectedCompany.id;
    
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Add custom header to show current view
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getFormatTitle(_calendarFormat),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Cycle through formats: Month -> 2 Weeks -> Week -> Month
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
                // CHANGE 1: Replace TableCalendar with BlocBuilder
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
                      ),
                      eventLoader: (day) => context.read<CalendarCubit>().getEventsForDay(day),
                      selectedDayPredicate: (day) {
                        return isSameDay(state.focusedDay, day);
                      },
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
                        context.read<CalendarCubit>().fetchEvents(companyId,
                          start: DateTime(focusedDay.year, focusedDay.month, 1),
                          end: DateTime(focusedDay.year, focusedDay.month + 1, 0));
                      },
                      calendarStyle: const CalendarStyle(
                        markersMaxCount: 3,
                      ),
                    );
                  }
                ),
                // CHANGE 2: Replace _buildEventList with BlocBuilder
                Expanded(
                  child: BlocBuilder<CalendarCubit, CalendarState>(
                    buildWhen: (previous, current) => 
                      previous.events != current.events || 
                      previous.focusedDay != current.focusedDay,
                    builder: (context, state) {
                      final events = context.read<CalendarCubit>().getEventsForDay(state.focusedDay);
                      
                      if (events.isEmpty) {
                        return const Center(
                          child: Text('No events for this day.'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (ctx, index) {
                          final event = events[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              title: Text(event.title),
                              subtitle: Text('${_formatTimeRange(event.startTime, event.endTime)}\n'
                                  'Created by: ${event.createdByName}'),
                              trailing: Text('${event.participants.length} participants'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EventDetailsScreen(event: event),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateEventScreen(),
            ),
          );
        },
        tooltip: 'Create Event',
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String _getFormatTitle(CalendarFormat format) {
    switch (format) {
      case CalendarFormat.month:
        return 'Month View';
      case CalendarFormat.twoWeeks:
        return '2 Weeks View';
      case CalendarFormat.week:
        return 'Week View';
      default:
        return '';
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}