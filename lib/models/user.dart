// ---------
// user
// ---------
enum AccessRole { collector, physician, researcher }

extension AccessRoleX on AccessRole {
  String get label {
    switch (this) {
      case AccessRole.collector:
        return 'Data Collector';
      case AccessRole.physician:
        return 'Physician';
      case AccessRole.researcher:
        return 'Researcher';
    }
  }

  int get level {
    switch (this) {
      case AccessRole.collector:
        return 1;
      case AccessRole.physician:
        return 2;
      case AccessRole.researcher:
        return 3;
    }
  }

  bool get canDiagnose => level >= 2;
  bool get canExport => level >= 3;
  bool get canViewTimestamps => level >= 3;
  bool get canManageData => level >= 3; // manage type
  bool get canViewRawLocation => level >= 2; // GPS coords
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final AccessRole role;
  final String? facilityName;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.facilityName,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'],
    fullName: m['fullName'],
    email: m['email'],
    role: AccessRole.values.firstWhere(
      (r) => r.name == m['role'],
      orElse: () => AccessRole.collector,
    ),
    facilityName: m['facilityName'],
    createdAt: DateTime.parse(m['createdAt']),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role.name,
    'facilityName': facilityName,
    'createdAt': createdAt.toIso8601String(),
  };
}
