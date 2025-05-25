import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:calendar_app/models/employee.dart';
import 'event_form/text_field_widget.dart';
import 'event_form/date_time_row_widget.dart';
import 'event_form/participants_selector.dart';

class EventWidgets {
  static final dateFormat = DateFormat('MMM dd, yyyy');

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return EventTextField(
      controller: controller,
      label: label,
      validator: validator,
      maxLines: maxLines,
    );
  }

  static Widget buildDateTimeRow({
    required String label,
    required String displayText,
    required VoidCallback onPressed,
  }) {
    return DateTimeRowWidget(
      label: label,
      displayText: displayText,
      onPressed: onPressed,
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

    return [
      ParticipantsSelector(
        employees: employees,
        selectedIds: selectedIds,
        onChanged: onChanged,
      )
    ];
  }
}
