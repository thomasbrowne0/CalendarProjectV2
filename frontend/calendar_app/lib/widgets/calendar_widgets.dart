// lib/widgets/calendar_widgets.dart
import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/edit_event_screen.dart';
import 'package:calendar_app/services/company_calendar_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final companyProvider = Provider.of<CompanyProvider>(context, listen: false);
    final canEdit = authProvider.user?.isCompanyOwner == true || 
                   event.createdById == authProvider.user?.id;

    return Card(
      elevation: 3,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventHeader(context, event, canEdit),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildDescriptionBox(context, event.description),
              ],
              const SizedBox(height: 16),
              _buildCreatorInfo(context, event.createdByName),
              if (event.participants.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildParticipantsList(context, event),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildEventHeader(BuildContext context, CalendarEvent event, bool canEdit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canEdit) _buildActionButtons(context, event),
      ],
    );
  }

  static Widget _buildActionButtons(BuildContext context, CalendarEvent event) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditEventScreen(event: event),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => _showDeleteDialog(context, event),
        ),
      ],
    );
  }

  static Widget _buildDescriptionBox(BuildContext context, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        description,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  static Widget _buildCreatorInfo(BuildContext context, String creatorName) {
    return Row(
      children: [
        Icon(
          Icons.person,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Created by: $creatorName',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  static Widget _buildParticipantsList(BuildContext context, CalendarEvent event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants (${event.participants.length}):',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: event.participants.map((participant) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      participant.firstName[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${participant.firstName} ${participant.lastName}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
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
