import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/event_details_screen.dart';
import 'package:calendar_app/services/calendar_service.dart';

class CalendarWidgets {
  static Widget buildEventList(List<CalendarEvent> events, BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No events for this day.'));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (ctx, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            title: Text(event.title),
            subtitle: Text('${CalendarService.formatTimeRange(event.startTime, event.endTime)}\n'
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

  static Widget noCompanySelected(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
