import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/services/create_event_service.dart';

class EventWidget extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final void Function(TimeOfDay) onStartTimeChanged;
  final void Function(TimeOfDay) onEndTimeChanged;
  final Set<String> selectedParticipantIds;
  final void Function(String id, bool selected) onParticipantToggle;

  const EventWidget({
    super.key,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.selectedParticipantIds,
    required this.onParticipantToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final employees = Provider.of<CompanyProvider>(context).employees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start Time', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: Text('${dateFormat.format(selectedDate)} ${startTime.format(context)}'),
            ),
            TextButton(
              onPressed: () => CreateEventService.selectTime(
                context: context,
                initialTime: startTime,
                onTimePicked: onStartTimeChanged,
              ),
              child: const Text('Change Time'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('End Time', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: Text('${dateFormat.format(selectedDate)} ${endTime.format(context)}'),
            ),
            TextButton(
              onPressed: () => CreateEventService.selectTime(
                context: context,
                initialTime: endTime,
                onTimePicked: onEndTimeChanged,
              ),
              child: const Text('Change Time'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (employees.isEmpty)
          const Text('No employees available')
        else
          ...employees.map((employee) => CheckboxListTile(
            title: Text('${employee.firstName} ${employee.lastName}'),
            subtitle: Text(employee.jobTitle),
            value: selectedParticipantIds.contains(employee.id),
            onChanged: (bool? value) {
              onParticipantToggle(employee.id, value ?? false);
            },
          )),
      ],
    );
  }
}
