import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created by: ${event.createdByName}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${dateFormat.format(event.startTime)} ${timeFormat.format(event.startTime)} - '
                            '${event.startTime.day != event.endTime.day ? "${dateFormat.format(event.endTime)} " : ""}'
                            '${timeFormat.format(event.endTime)}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description.isNotEmpty 
                        ? event.description 
                        : 'No description provided.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Participants',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (event.participants.isEmpty)
              const Text('No participants')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: event.participants.length,
                itemBuilder: (ctx, index) {
                  final participant = event.participants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(participant.firstName[0] + participant.lastName[0]),
                    ),
                    title: Text('${participant.firstName} ${participant.lastName}'),
                    subtitle: Text(participant.jobTitle),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
