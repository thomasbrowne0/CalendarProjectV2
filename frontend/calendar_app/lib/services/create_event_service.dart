import 'package:flutter/material.dart';
import 'package:calendar_app/providers/company_provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:provider/provider.dart';

class CreateEventService {
  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static Future<DateTime?> pickDate(BuildContext context, DateTime initialDate,
      {required DateTime firstDate, required DateTime lastDate}) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  static Future<TimeOfDay?> pickTime(BuildContext context, TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }

  static Future<void> submit({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
    required Set<String> selectedParticipantIds,
    required VoidCallback onSuccess,
    required Function(String title, String message) showError,
    required Function(bool isLoading) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final startDateTime = combineDateAndTime(startDate, startTime);
    final endDateTime = combineDateAndTime(endDate, endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setLoading(true);
    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false).selectedCompany!.id;
      final participantIds = selectedParticipantIds.toList();

      await Provider.of<CalendarProvider>(context, listen: false).createEvent(
        companyId,
        titleController.text,
        descriptionController.text,
        startDateTime,
        endDateTime,
        participantIds,
      );

      onSuccess();
    } catch (error) {
      showError('Failed to create event', error.toString());
    }
    setLoading(false);
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
