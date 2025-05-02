import 'package:calendar_app/models/employee.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String createdById;
  final String createdByName;
  final String companyId;
  final List<Employee> participants;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.createdById,
    required this.createdByName,
    required this.companyId,
    required this.participants,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      createdById: json['createdById'],
      createdByName: json['createdByName'] ?? '',
      companyId: json['companyId'],
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => Employee.fromJson(p))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'createdById': createdById,
      'companyId': companyId,
      'participantIds': participants.map((p) => p.id).toList(),
    };
  }
}
