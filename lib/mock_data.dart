// ─────────────────────────────────────────────────────────────────────────────
//  Mock data for development
// ─────────────────────────────────────────────────────────────────────────────
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';

final List<PatientRecord> kMockPatients = [
  PatientRecord(
    id: '1', idNumber: 'GHA-001-2509230634',
    locationCoords: '5.6037168, -0.6914456',
    fullName: 'Kofi Abankwah',
    dateOfBirth: DateTime(1990, 1, 2),
    phone: '0244567893', sex: 'M',
    emergencyName: 'Agyarkwah Kwapong', emergencyContact: '02679283283',
    photoUrls: [], clinicalNotes: 'Ulcerated painless lesion.',
    collectorId: 'c1', facilityName: 'Korle Bu Teaching Hospital',
    collectedAt: DateTime(2025, 8, 25, 16, 32),
    updatedAt: DateTime(2025, 8, 25, 16, 32),
    diagnosis: Diagnosis(
      physicianId: 'p1', physicianName: 'Dr. Mensah',
      ntdType: SkinNtdType.buruliUlcer,
      status: DiagnosisStatus.confirmed,
      clinicalFindings: 'Classic Buruli ulcer presentation.',
      treatmentPlan: 'Rifampicin + Clarithromycin 8 weeks.',
      diagnosedAt: DateTime(2025, 8, 26, 9, 0),
    ),
  ),
  PatientRecord(
    id: '2', idNumber: 'GHA-002-2509230891',
    locationCoords: '5.5502, -0.2174',
    fullName: 'Yaa Fofie',
    dateOfBirth: DateTime(1985, 6, 15),
    phone: '0201234567', sex: 'F',
    emergencyName: 'Kwame Fofie', emergencyContact: '0277654321',
    photoUrls: [], clinicalNotes: '',
    collectorId: 'c1', facilityName: 'Ridge Hospital',
    collectedAt: DateTime(2025, 8, 25, 16, 28),
    updatedAt: DateTime(2025, 8, 25, 16, 28),
  ),
  PatientRecord(
    id: '3', idNumber: 'GHA-003-2509231102',
    locationCoords: '5.7550, -0.2200',
    fullName: 'Kofi Abankwah',
    dateOfBirth: DateTime(1978, 11, 3),
    phone: '0559876543', sex: 'M',
    emergencyName: 'Akua Abankwah', emergencyContact: '0241234567',
    photoUrls: [], clinicalNotes: 'Multiple lesions on lower limb.',
    collectorId: 'c2', facilityName: 'KATH',
    collectedAt: DateTime(2025, 8, 25, 16, 32),
    updatedAt: DateTime(2025, 8, 25, 16, 32),
  ),
];