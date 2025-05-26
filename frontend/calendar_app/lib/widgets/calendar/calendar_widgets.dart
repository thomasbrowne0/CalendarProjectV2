// lib/widgets/calendar_widgets.dart
import 'package:flutter/material.dart';
import 'package:calendar_app/models/calendar_event.dart';
import 'package:calendar_app/models/employee.dart';
import 'package:intl/intl.dart';
import 'package:calendar_app/widgets/events/event_form.dart';
import 'package:calendar_app/widgets/events/event_card.dart';

class CalendarWidgets {
  static final dateFormat = DateFormat('MMM dd, yyyy');

  // Delegate to specialized widget classes
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) =>
      EventFormWidgets.buildTextField(
        controller: controller,
        label: label,
        validator: validator,
        maxLines: maxLines,
      );

  static Widget buildDateTimeRow({
    required String label,
    required String displayText,
    required VoidCallback onPressed,
  }) =>
      EventFormWidgets.buildDateTimeRow(
        label: label,
        displayText: displayText,
        onPressed: onPressed,
      );

  static List<Widget> buildParticipantCheckboxes({
    required List<Employee> employees,
    required Set<String> selectedIds,
    required void Function(String id, bool isSelected) onChanged,
  }) =>
      EventFormWidgets.buildParticipantCheckboxes(
        employees: employees,
        selectedIds: selectedIds,
        onChanged: onChanged,
      );

  static Widget buildEventCard(CalendarEvent event, BuildContext context) =>
      EventCard(event: event);

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
}
