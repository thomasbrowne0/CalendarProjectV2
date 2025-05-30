import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/company_calendar_service.dart';

class CalendarHeader extends StatelessWidget {
  final CalendarFormat calendarFormat;
  final VoidCallback onFormatToggle;

  const CalendarHeader({
    super.key,
    required this.calendarFormat,
    required this.onFormatToggle,
  });

  @override
  Widget build(BuildContext context) {
    final calendarService = CompanyCalendarService();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            calendarService.getFormatTitle(calendarFormat),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onFormatToggle,
            child: const Text('Change View'),
          )
        ],
      ),
    );
  }
}
