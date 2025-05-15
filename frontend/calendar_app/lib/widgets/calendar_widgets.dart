// lib/widgets/calendar_widgets.dart
import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/event_details_screen.dart';
import 'package:calendar_app/services/company_calendar_service.dart';

class CalendarWidgets {
  static Widget noCompanySelectedWidget(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.business, size: 80, color: Colors.black),
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
              Navigator.of(context).pop();
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  static Widget buildEventCard(CalendarEvent event, BuildContext context) {
    final timeRange = CompanyCalendarService().formatTimeRange(event.startTime, event.endTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(event.title),
        subtitle: Text('$timeRange\nCreated by: ${event.createdByName}'),
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
  }
}
