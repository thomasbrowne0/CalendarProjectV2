import 'package:flutter/material.dart';

class EventDescriptionBox extends StatelessWidget {
  final String description;

  const EventDescriptionBox({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
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
}

class EventCreatorInfo extends StatelessWidget {
  final String creatorName;

  const EventCreatorInfo({super.key, required this.creatorName});

  @override
  Widget build(BuildContext context) {
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
}