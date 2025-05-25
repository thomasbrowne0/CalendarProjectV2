// lib/services/company_calendar_service.dart
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CompanyCalendarService {
  String formatTimeRange(DateTime start, DateTime end) {
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  String getFormatTitle(CalendarFormat format) {
    switch (format) {
      case CalendarFormat.month:
        return 'Month View';
      case CalendarFormat.twoWeeks:
        return '2 Weeks View';
      case CalendarFormat.week:
        return 'Week View';
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  CalendarFormat getNextCalendarFormat(CalendarFormat currentFormat) {
    switch (currentFormat) {
      case CalendarFormat.month:
        return CalendarFormat.twoWeeks;
      case CalendarFormat.twoWeeks:
        return CalendarFormat.week;
      case CalendarFormat.week:
        return CalendarFormat.month;
    }
  }

  String formatDateForEvents(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  String getEventsHeaderText(DateTime date) {
    return 'Events for ${formatDateForEvents(date)}';
  }
}
