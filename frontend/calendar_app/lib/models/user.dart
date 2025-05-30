class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;

  // final String mobilePhone;
  final String userType;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    // required this.mobilePhone,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      //  mobilePhone: json['mobilePhone'],
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      // 'mobilePhone': mobilePhone,
      'userType': userType,
    };
  }

  String get fullName => '$firstName $lastName';

  bool get isCompanyOwner => userType == 'CompanyOwner';
}
