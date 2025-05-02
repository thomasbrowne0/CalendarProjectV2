class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String jobTitle;
  final String companyId;
  final String companyName;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.jobTitle,
    required this.companyId,
    this.companyName = '',
  });

  String get fullName => '$firstName $lastName';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      jobTitle: json['jobTitle'],
      companyId: json['companyId'],
      companyName: json['companyName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'jobTitle': jobTitle,
      'companyId': companyId,
      'companyName': companyName,
    };
  }
}
