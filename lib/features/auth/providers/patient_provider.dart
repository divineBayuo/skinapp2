// -- Patient State -----
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/mock_data.dart';

class PatientState {
  final List<PatientRecord> records;
  final bool loading;
  final String? error;

  const PatientState({
    this.records = const [],
    this.loading = false,
    this.error,
  });

  PatientState copyWith({
    List<PatientRecord>? records,
    bool? loading,
    String? error,
  }) {
    return PatientState(
      records: records ?? this.records,
      loading: loading ?? this.loading,
      error: error ?? this.error,
    );
  }
}

// -- Patient Notifier -------------
class PatientNotifier extends StateNotifier<PatientState> {
  PatientNotifier() : super(const PatientState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(loading: true);
    try {
      // TODO: Replace with Firestorm stream
      // FirebaseFirestore.instance.collection('patients')
      //  .orderBy('collectedAt', descending: true)
      //  .snapshots().listen((snap) {
      //    state = state.copyWith(
      //      records: snap.docs.map((d) =>
      //        PatientRecord.fromMap({'id': d.id, ...d.data()})).toList(),
      //      loading: false,
      //     );
      //    })

      await Future.delayed(const Duration(milliseconds: 500));
      state = state.copyWith(records: kMockPatients, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> addRecord(PatientRecord record) async {
    try {
      // TODO: await FirebaseFirestore.instance
      //  .collection('patients').add(record.toMap());
      state = state.copyWith(records: [record, ...state.records]);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addDiagnosis(String patientId, Diagnosis diagnosis) async {
    try {
      // TODO: Firestore update
      final updated = state.records.map((p) {
        if (p.id == patientId) {
          return PatientRecord(
            id: p.id,
            idNumber: p.idNumber,
            locationCoords: p.locationCoords,
            fullName: p.fullName,
            dateOfBirth: p.dateOfBirth,
            phone: p.phone,
            sex: p.sex,
            emergencyName: p.emergencyName,
            emergencyContact: p.emergencyContact,
            photoUrls: p.photoUrls,
            clinicalNotes: p.clinicalNotes,
            collectorId: p.collectorId,
            facilityName: p.facilityName,
            collectedAt: p.collectedAt,
            updatedAt: DateTime.now(),
            diagnosis: diagnosis,
          );
        }
        return p;
      }).toList();
      state = state.copyWith(records: updated);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Search/filter helpers
  List<PatientRecord> search(String query) {
    if (query.isEmpty) return state.records;
    final q = query.toLowerCase();
    return state.records
        .where(
          (p) =>
              p.fullName.toLowerCase().contains(q) ||
              p.idNumber.toLowerCase().contains(q) ||
              p.district.toLowerCase().contains(q),
        )
        .toList();
  }

  List<PatientRecord> filterByDate(DateTime date) {
    return state.records
        .where(
          (p) =>
              p.collectedAt.year == date.year &&
              p.collectedAt.month == date.month &&
              p.collectedAt.day == date.day,
        )
        .toList();
  }

  List<PatientRecord> get pending =>
      state.records.where((p) => !p.hasDiagnosis).toList();

  List<PatientRecord> get diagnosed =>
      state.records.where((p) => p.hasDiagnosis).toList();
}

// -- Providers -------------
final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>(
  (ref) => PatientNotifier(),
);

final pendingPatientsProvider = Provider<List<PatientRecord>>((ref) {
  return ref
      .watch(patientProvider)
      .records
      .where((p) => !p.hasDiagnosis)
      .toList();
});

final diagnosedPatientsProvider = Provider<List<PatientRecord>>((ref) {
  return ref
      .watch(patientProvider)
      .records
      .where((p) => p.hasDiagnosis)
      .toList();
});

// Dummy 'district' field - add to PatientRecord if needed
extension PatientRecordX on PatientRecord {
  String get district => locationCoords; // placeholder
}
