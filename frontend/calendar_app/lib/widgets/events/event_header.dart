import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:intl/intl.dart';
import 'event_actions.dart';

class EventCardHeader extends StatelessWidget {
  final CalendarEvent event;
  final bool canEdit;

  const EventCardHeader({
    super.key,
    required this.event,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: EventTitleAndTime(event: event)),
        if (canEdit) EventActionButtons(event: event),
      ],
    );
  }
}

class EventTitleAndTime extends StatelessWidget {
  final CalendarEvent event;

  const EventTitleAndTime({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventTitle(title: event.title),
        const SizedBox(height: 8),
        EventTimeDisplay(
          startTime: event.startTime,
          endTime: event.endTime,
        ),
      ],
    );
  }
}

class EventTitle extends StatelessWidget {
  final String title;

  const EventTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class EventTimeDisplay extends StatelessWidget {
  final DateTime startTime;
  final DateTime endTime;

  const EventTimeDisplay({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}