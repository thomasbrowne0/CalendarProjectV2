import 'package:flutter/material.dart';
import 'package:calendar_app/models/employee.dart';
import 'package:calendar_app/services/event_service.dart';
import 'package:intl/intl.dart';

class EventFormWidgets {
  static final dateFormat = DateFormat('MMM dd, yyyy');

  // Basic form components
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

  // Higher-level form sections
  static Widget buildEventFormFields({
    required TextEditingController titleController,
    required TextEditingController descriptionController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildTextField(
          controller: titleController,
          label: 'Event Title',
          validator: (value) => (value == null || value.isEmpty) ? 'Please enter an event title' : null,
        ),
        const SizedBox(height: 12),
        buildTextField(
          controller: descriptionController,
          label: 'Description',
          maxLines: 3,
        ),
      ],
    );
  }

  static Widget buildTimeSection({
    required String sectionTitle,
    required DateTime date,
    required TimeOfDay time,
    required BuildContext context,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(sectionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text('Date: ${dateFormat.format(date)}'),
        ),
        buildDateTimeRow(
          label: 'Time',
          displayText: time.format(context),
          onPressed: () async {
            final picked = await EventService.pickTime(context, time);
            if (picked != null) onTimeChanged(picked);
          },
        ),
      ],
    );
  }

  static Widget buildParticipantsSection({
    required List employees,
    required Set<String> selectedIds,
    required Function(String, bool) onParticipantToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Participants', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...buildParticipantCheckboxes(
          employees: employees.cast<Employee>(),
          selectedIds: selectedIds,
          onChanged: onParticipantToggle,
        ),
      ],
    );
  }

  static Widget buildSubmitButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required String buttonText,
  }) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(buttonText),
          );
  }
}