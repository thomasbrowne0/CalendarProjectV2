import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/create_event_screen.dart';
import 'package:calendar_app/screens/event_details_screen.dart';

class CompanyCalendarScreen extends StatefulWidget {
  @override
  _CompanyCalendarScreenState createState() => _CompanyCalendarScreenState();
}

class _CompanyCalendarScreenState extends State<CompanyCalendarScreen> {
  bool _isInit = true;
  bool _isLoading = false;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });
      
      final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
      // Check if there's a selected company before trying to access its id
      if (companyProvider.selectedCompany != null) {
        final companyId = companyProvider.selectedCompany!.id;
        Provider.of<CalendarProvider>(context, listen: false)
            .fetchEvents(companyId)
            .then((_) {
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
            // Optionally show an error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load events: ${error.toString()}')),
            );
          }
        });
      } else {
        // No company selected, handle this case
        setState(() {
          _isLoading = false;
        });
        // Optionally show a message to select a company
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a company first')),
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
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final companyProvider = Provider.of<CompanyProvider>(context);
    final selectedCompany = companyProvider.selectedCompany;
    
    // If no company is selected, show a message
    if (selectedCompany == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Company Calendar'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(); // Go back to previous screen
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No company selected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please select a company to view its calendar'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Go back to company selection
                },
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    
    final companyId = selectedCompany.id;
    
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        child: Text('Change View'),
                      )
                    ],
                  ),
                ),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: calendarProvider.focusedDay,
                  calendarFormat: _calendarFormat,
                  rangeSelectionMode: _rangeSelectionMode,
                  // Just use headerStyle to hide the format button
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  eventLoader: (day) => calendarProvider.getEventsForDay(day),
                  selectedDayPredicate: (day) {
                    return isSameDay(calendarProvider.focusedDay, day);
                  },
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
                    // Only fetch events if we have a valid company
                    if (selectedCompany != null) {
                      calendarProvider.fetchEvents(companyId,
                        start: DateTime(focusedDay.year, focusedDay.month, 1),
                        end: DateTime(focusedDay.year, focusedDay.month + 1, 0));
                    }
                  },
                  calendarStyle: CalendarStyle(
                    markersMaxCount: 3,
                  ),
                ),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateEventScreen(),
            ),
          );
        },
        tooltip: 'Create Event',
      ),
    );
  }

  Widget _buildEventList() {
    final calendarProvider = Provider.of<CalendarProvider>(context);
    final events = calendarProvider.getEventsForDay(calendarProvider.focusedDay);

    if (events.isEmpty) {
      return Center(
        child: Text('No events for this day.'),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final event = events[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
}
