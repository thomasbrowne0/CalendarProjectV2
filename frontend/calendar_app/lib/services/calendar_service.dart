import 'package:table_calendar/table_calendar.dart';

class CalendarService {
  static String formatTimeRange(DateTime start, DateTime end) {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  static String getFormatTitle(CalendarFormat format) {
    switch (format) {
      case CalendarFormat.month:
        return 'Month View';
      case CalendarFormat.twoWeeks:
        return '2 Weeks View';
      case CalendarFormat.week:
        return 'Week View';
      default:
        return '';
    }
  }
}
