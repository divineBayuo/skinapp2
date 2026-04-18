// -----------
// patient.dart
// -------------

import 'package:skinapp2/models/diagnosis.dart';

class PatientRecord {
  final String id;

  // auto gen fields
  final String idNumber;
  final String locationCoords;

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

  // Physician-added diagnosis
  final Diagnosis? diagnosis;

  const PatientRecord({
    required this.id,
    required this.idNumber,
    required this.locationCoords,
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

  factory PatientRecord.fromMap(Map<String, dynamic> m) => PatientRecord(
    id: m['id'],
    idNumber: m['idNumber'],
    locationCoords: m['locationCoords'],
    fullName: m['fullName'],
    dateOfBirth: DateTime.parse(m['dateOfBirth']),
    phone: m['phone'],
    sex: m['sex'],
    emergencyName: m['emergencyName'],
    emergencyContact: m['emergencyContact'],
    photoUrls: List<String>.from(m['photoUrls'] ?? []),
    clinicalNotes: m['clinicalNotes'] ?? '',
    collectorId: m['collectorId'],
    facilityName: m['facilityName'],
    collectedAt: DateTime.parse(m['collectedAt']),
    updatedAt: DateTime.parse(m['updatedAt']),
    diagnosis: m['diagnosis'] != null
        ? Diagnosis.fromMap(m['diagnosis'])
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'idNumber': idNumber,
    'locationCoords': locationCoords,
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
    'diagnosis': diagnosis?.toMap(),
  };
}
