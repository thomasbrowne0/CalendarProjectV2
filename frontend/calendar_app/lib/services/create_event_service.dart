import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calendar_app/providers/calendar_provider.dart';
import 'package:calendar_app/providers/company_provider.dart';

import '../cubit/calendar_cubit.dart';

class CreateEventService {
  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static Future<void> selectTime({
    required BuildContext context,
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onTimePicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimePicked(picked);
    }
  }

  static Future<void> submitEvent({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required DateTime selectedDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String title,
    required String description,
    required Set<String> selectedParticipantIds,
    required VoidCallback onSuccess,
    required Function(String, String) onError,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final startDateTime = combineDateAndTime(selectedDate, startTime);
    final endDateTime = combineDateAndTime(selectedDate, endTime);

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    try {
      final companyId = Provider.of<CompanyProvider>(context, listen: false)
          .selectedCompany!
          .id;

      final createdEvent = await Provider.of<CalendarProvider>(context, listen: false).createEvent(
        companyId,
        title,
        description,
        startDateTime,
        endDateTime,
        selectedParticipantIds.toList(),
      );

      // Add the new event to CalendarCubit for instant UI update
      context.read<CalendarCubit>().addEvent(createdEvent);

      onSuccess();
    } catch (error) {
      onError('Failed to create event', error.toString());
    }
  }
}
