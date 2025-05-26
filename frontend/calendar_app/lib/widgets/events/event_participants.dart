import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';

class EventParticipantsList extends StatelessWidget {
  final CalendarEvent event;

  const EventParticipantsList({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ParticipantsHeader(count: event.participants.length),
        const SizedBox(height: 8),
        ParticipantsChips(participants: event.participants),
      ],
    );
  }
}

class ParticipantsHeader extends StatelessWidget {
  final int count;

  const ParticipantsHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Participants ($count):',
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class ParticipantsChips extends StatelessWidget {
  final List participants;

  const ParticipantsChips({super.key, required this.participants});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: participants.map((participant) {
        return ParticipantChip(participant: participant);
      }).toList(),
    );
  }
}

class ParticipantChip extends StatelessWidget {
  final dynamic participant;

  const ParticipantChip({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
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
          ParticipantAvatar(firstName: participant.firstName),
          const SizedBox(width: 8),
          ParticipantName(
            firstName: participant.firstName,
            lastName: participant.lastName,
          ),
        ],
      ),
    );
  }
}

class ParticipantAvatar extends StatelessWidget {
  final String firstName;

  const ParticipantAvatar({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 12,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
        firstName[0],
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ParticipantName extends StatelessWidget {
  final String firstName;
  final String lastName;

  const ParticipantName({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$firstName $lastName',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}