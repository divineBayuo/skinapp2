// --------------
// NTD types
// -------------

enum SkinNtdType {
  buruliUlcer,
  leprosy,
  yaws,
  scabies,
  leishmaniasis,
  lymphaticFilariasis,
  fungalInfection,
  unknown,
}

extension SkinNtdTypeX on SkinNtdType {
  String get label {
    switch (this) {
      case SkinNtdType.buruliUlcer:
        return 'Buruli Ulcer';
      case SkinNtdType.leprosy:
        return 'Leprosy';
      case SkinNtdType.yaws:
        return 'Yaws';
      case SkinNtdType.scabies:
        return 'Scabies';
      case SkinNtdType.leishmaniasis:
        return 'Leishmaniasis';
      case SkinNtdType.lymphaticFilariasis:
        return 'Lymphatic Filariasis';
      case SkinNtdType.fungalInfection:
        return 'Fungal Infection';
      case SkinNtdType.unknown:
        return 'Unknown / Pending';
    }
  }
}

// diagnosis status
enum DiagnosisStatus { confirmed, suspected, ruledOut, pendingTest }

extension DiagnosisStatusX on DiagnosisStatus {
  String get label {
    switch (this) {
      case DiagnosisStatus.confirmed:
        return 'Confirmed';
      case DiagnosisStatus.suspected:
        return 'Suspected';
      case DiagnosisStatus.ruledOut:
        return 'Ruled Out';
      case DiagnosisStatus.pendingTest:
        return 'Pending Test';
    }
  }
}

// diagnosis class
class Diagnosis {
  final String physicianId;
  final String physicianName;
  final SkinNtdType ntdType;
  final DiagnosisStatus status;
  final String clinicalFindings;
  final String treatmentPlan;
  final DateTime diagnosedAt;
  final DateTime? followUpDate;

  const Diagnosis({
    required this.physicianId,
    required this.physicianName,
    required this.ntdType,
    required this.status,
    required this.clinicalFindings,
    required this.treatmentPlan,
    required this.diagnosedAt,
    this.followUpDate,
  });

  factory Diagnosis.fromMap(Map<String, dynamic> m) => Diagnosis(
    physicianId: m['physicianId'],
    physicianName: m['physicianName'],
    ntdType: SkinNtdType.values.firstWhere(
      (t) => t.name == m['ntdType'],
      orElse: () => SkinNtdType.unknown,
    ),
    status: DiagnosisStatus.values.firstWhere(
      (s) => s.name == m['status'],
      orElse: () => DiagnosisStatus.suspected,
    ),
    clinicalFindings: m['clinicalFindings'] ?? '',
    treatmentPlan: m['treatmentPlan'] ?? '',
    diagnosedAt: DateTime.parse(m['diagnosedAt']),
    followUpDate: m['followUpDate'] != null
        ? DateTime.parse(m['followUpDate'])
        : null,
  );

  Map<String, dynamic> toMap() => {
    'physicianId': physicianId,
    'physicianName': physicianName,
    'ntdType': ntdType.name,
    'status': status.name,
    'clinicalFindings': clinicalFindings,
    'treatmentPlan': treatmentPlan,
    'diagnosedAt': diagnosedAt.toIso8601String(),
    'followUpDate': followUpDate?.toIso8601String(),
  };
}
