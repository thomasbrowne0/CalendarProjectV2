import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:calendar_app/screens/edit_event_screen.dart';

class EventDetailsScreen extends StatelessWidget {
  final CalendarEvent event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final isCompanyOwner = authProvider.user?.isCompanyOwner ?? false;
    final isEventCreator = event.createdById == authProvider.user?.id;
    final canModifyEvent = isCompanyOwner || isEventCreator;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (canModifyEvent)
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).shadowColor.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editEvent(context),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        Container(
                          height: 24,
                          width: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteEvent(context),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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

  void _editEvent(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventScreen(event: event),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  void _deleteEvent(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        final companyId = Provider.of<CompanyProvider>(context, listen: false)
            .selectedCompany!
            .id;
        await context.read<CalendarCubit>().deleteEvent(companyId, event.id);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete event: ${error.toString()}')),
          );
        }
      }
    }
  }
}