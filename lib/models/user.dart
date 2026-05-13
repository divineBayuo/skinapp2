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
  bool get canManageData => level >= 2; // manage type
  bool get canViewRawLocation => level >= 2; // GPS coords

  bool get isCollector => this == AccessRole.collector;
  bool get isPhysician => this == AccessRole.physician;
  bool get isResearcher => this == AccessRole.researcher;
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final AccessRole role;
  final String? facilityName;
  final DateTime createdAt;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.facilityName,
    required this.createdAt,
    this.isActive = true,
  });

  /// Constructs an AppUser from a Firestore document map.
  /// Call as: AppUser.fromMap({'id': uid, ...doc.data()!})
  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'] as String,
    fullName: m['fullName'] as String,
    email: m['email'] as String,
    role: AccessRole.values.firstWhere(
      (r) => r.name == (m['role'] as String),
      orElse: () => AccessRole.collector,
    ),
    facilityName: m['facilityName'] as String?,
    createdAt: DateTime.parse(m['createdAt'] as String),
    isActive: (m['isActive'] as bool?) ?? true,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role.name,
    'facilityName': facilityName,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  // Return initials from the full name
  String get initials {
    final parts = fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // Returns first name only
  String get firstName {
    return fullName.trim().split(' ').first;
  }
}
