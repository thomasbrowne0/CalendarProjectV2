import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/event/edit_event_screen.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';

class EventActionButtons extends StatelessWidget {
  final CalendarEvent event;

  const EventActionButtons({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditEventButton(event: event),
        DeleteEventButton(event: event),
      ],
    );
  }
}

class EditEventButton extends StatelessWidget {
  final CalendarEvent event;

  const EditEventButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.edit,
        color: Theme
            .of(context)
            .colorScheme
            .inverseSurface,
      ),
      onPressed: () =>
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditEventScreen(event: event),
            ),
          ),
    );
  }
}

class DeleteEventButton extends StatelessWidget {
  final CalendarEvent event;

  const DeleteEventButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.delete,
        color: Theme
            .of(context)
            .colorScheme
            .secondary,
      ),
      onPressed: () => _showDeleteDialog(context),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => const DeleteEventDialog(),
    );

    if (confirm == true && context.mounted) {
      try {
        final companyId = Provider
            .of<CompanyProvider>(context, listen: false)
            .selectedCompany!
            .id;
        await context.read<CalendarCubit>().deleteEvent(companyId, event.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to delete event: ${error.toString()}')),
          );
        }
      }
    }
  }
}

class DeleteEventDialog extends StatelessWidget {
  const DeleteEventDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Event'),
      content: const Text('Are you sure you want to delete this event?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme
                .of(context)
                .colorScheme
                .error,
          ),
          child: const Text('DELETE'),
        ),
      ],
    );
  }
}