// -----------
// patient.dart
// -------------

import 'package:skinapp2/models/diagnosis.dart';

class PatientRecord {
  final String id;

  // auto gen fields
  final String idNumber;
  final String locationCoords;
  final String community;

  // collector-entered fields
  final String fullName;
  final DateTime dateOfBirth;
  final String phone;
  final String sex;
  final String emergencyName;
  final String emergencyContact;

  // Clinical data
  final List<String> photoUrls;
  final String clinicalNotes;

  // Metadata
  final String collectorId;
  final String facilityName;
  final DateTime collectedAt;
  final DateTime updatedAt;

  final DateTime? sentAt;
  final DateTime? receivedAt;

  // Physician-added diagnosis
  final Diagnosis? diagnosis;

  const PatientRecord({
    required this.id,
    required this.idNumber,
    required this.locationCoords,
    this.community = '',
    required this.fullName,
    required this.dateOfBirth,
    required this.phone,
    required this.sex,
    required this.emergencyName,
    required this.emergencyContact,
    required this.photoUrls,
    required this.clinicalNotes,
    required this.collectorId,
    required this.facilityName,
    required this.collectedAt,
    required this.updatedAt,
    this.sentAt,
    this.receivedAt,
    this.diagnosis,
  });

  bool get hasDiagnosis => diagnosis != null;

  String get firstName {
    final parts = fullName.trim().split(' ');
    return parts.first;
  }

  String get lastName {
    final parts = fullName.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }

  int get ageInYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day))
      age--;
    return age;
  }

  String get formattedDob {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dateOfBirth.day.toString().padLeft(2, '0')}-${months[dateOfBirth.month - 1]}- ${dateOfBirth.year}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String get formattedTimestamp {
    final d = collectedAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}-${months[d.month - 1]}-${d.year} | $h:$m';
  }

  // NEW: formatted sent timestamp
  String get formattedSentAt {
    if (sentAt == null) return '—';
    final d = sentAt!;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}-${_months[d.month - 1]}-${d.year} $h:$m';
  }

  // NEW: formatted received timestamp
  String get formattedReceivedAt {
    if (receivedAt == null) return 'Pending sync';
    final d = receivedAt!;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}-${_months[d.month - 1]}-${d.year} $h:$m';
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    // Firestore Timestamp object when read back from Firestore
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['_seconds'] as int) * 1000,
      );
    }

    // already a string when read from sqlite
    if (value is String) return DateTime.tryParse(value);
    // cloud_firestore Timestamp type
    try {
      // ignore: avoid dynamic calls
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return null;
    }
  }

  factory PatientRecord.fromMap(Map<String, dynamic> m) => PatientRecord(
    id: m['id'] as String? ?? '',
    idNumber: m['idNumber'] as String? ?? '',
    locationCoords: m['locationCoords'] as String? ?? '',
    community: m['community'] as String? ?? '',
    fullName: m['fullName'] as String? ?? '',
    dateOfBirth: DateTime.parse(m['dateOfBirth'] as String),
    phone: m['phone'] as String? ?? '',
    sex: m['sex'] as String? ?? '',
    emergencyName: m['emergencyName'] as String? ?? '',
    emergencyContact: m['emergencyContact'] as String? ?? '',
    photoUrls:
        (m['photoUrls'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    clinicalNotes: m['clinicalNotes'] as String? ?? '',
    collectorId: m['collectorId'] as String? ?? '',
    facilityName: m['facilityName'] as String? ?? '',
    collectedAt: DateTime.parse(m['collectedAt'] as String),
    updatedAt: DateTime.parse(m['updatedAt'] as String),
    sentAt: m['sentAt'] != null
        ? DateTime.tryParse(m['sentAt'] as String)
        : null,
    receivedAt: _parseTimestamp(m['receivedAt']),
    diagnosis: m['diagnosis'] != null
        ? Diagnosis.fromMap(m['diagnosis'] as Map<String, dynamic>)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'idNumber': idNumber,
    'locationCoords': locationCoords,
    'community': community,
    'fullName': fullName,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'phone': phone,
    'sex': sex,
    'emergencyName': emergencyName,
    'emergencyContact': emergencyContact,
    'photoUrls': photoUrls,
    'clinicalNotes': clinicalNotes,
    'collectorId': collectorId,
    'facilityName': facilityName,
    'collectedAt': collectedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'receivedAt': receivedAt?.toIso8601String(),
    'diagnosis': diagnosis?.toMap(),
  };
}
