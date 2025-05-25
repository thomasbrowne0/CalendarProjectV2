// lib/widgets/calendar_widgets.dart
import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/edit_event_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'calendar_widgets/event_card.dart';
import 'calendar_widgets/no_company_widget.dart';

// Main class now just delegates to more focused widgets
class CalendarWidgets {
  static Widget noCompanySelectedWidget(BuildContext context) {
    return const NoCompanySelectedWidget();
  }

  static Widget buildEventCard(CalendarEvent event, BuildContext context) {
    return EventCard(event: event);
  }

  static Future<void> _showDeleteDialog(BuildContext context, CalendarEvent event) async {
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
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
