import 'package:flutter/material.dart';
import 'package:calendar_app/models/employee.dart';

class ParticipantsSelector extends StatelessWidget {
  final List<Employee> employees;
  final Set<String> selectedIds;
  final void Function(String id, bool isSelected) onChanged;

  const ParticipantsSelector({
    super.key,
    required this.employees,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: employees.map(
        (e) => CheckboxListTile(
          title: Text('${e.firstName} ${e.lastName}'),
          subtitle: Text(e.jobTitle),
          value: selectedIds.contains(e.id),
          onChanged: (bool? value) {
            onChanged(e.id, value ?? false);
          },
        ),
      ).toList(),
    );
  }
}
