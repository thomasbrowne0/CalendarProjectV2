class Company {
  final String id;
  final String name;
  final String cvr;
  final String companyOwnerId;
  final String ownerName;
  final int employeeCount;

  Company({
    required this.id,
    required this.name,
    required this.cvr,
    required this.companyOwnerId,
    required this.ownerName,
    this.employeeCount = 0,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'],
      cvr: json['cvr'],
      companyOwnerId: json['companyOwnerId'],
      ownerName: json['ownerName'] ?? '',
      employeeCount: json['employeeCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cvr': cvr,
      'companyOwnerId': companyOwnerId,
      'ownerName': ownerName,
      'employeeCount': employeeCount,
    };
  }
}
