import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_app/models/employee.dart';

class CreateEventWidgets {
  static final dateFormat = DateFormat('MMM dd, yyyy');

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: validator,
      maxLines: maxLines,
    );
  }

  static Widget buildDateTimeRow({
    required String label,
    required String displayText,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        Expanded(child: Text(displayText)),
        TextButton(onPressed: onPressed, child: Text('Change $label')),
      ],
    );
  }

  static List<Widget> buildParticipantCheckboxes({
    required List<Employee> employees,
    required Set<String> selectedIds,
    required void Function(String id, bool isSelected) onChanged,
  }) {
    if (employees.isEmpty) {
      return [const Text('No employees available')];
    }

    return employees
        .map(
          (e) => CheckboxListTile(
        title: Text('${e.firstName} ${e.lastName}'),
        subtitle: Text(e.jobTitle),
        value: selectedIds.contains(e.id),
        onChanged: (bool? value) {
          onChanged(e.id, value ?? false);
        },
      ),
    )
        .toList();
  }

  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
