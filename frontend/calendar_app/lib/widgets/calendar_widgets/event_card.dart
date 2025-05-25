import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/screens/edit_event_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/auth_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:calendar_app/cubit/calendar_cubit.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'event_header.dart';
import 'description_box.dart';
import 'creator_info.dart';
import 'participants_list.dart';

class EventCard extends StatelessWidget {
  final CalendarEvent event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
              EventHeader(event: event, canEdit: canEdit),
              if (event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                DescriptionBox(description: event.description),
              ],
              const SizedBox(height: 16),
              CreatorInfo(creatorName: event.createdByName),
              if (event.participants.isNotEmpty) ...[
                const SizedBox(height: 16),
                ParticipantsList(participants: event.participants),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
