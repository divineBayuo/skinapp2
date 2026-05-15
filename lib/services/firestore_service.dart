import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skinapp2/models/patient.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('patients');

  // Fetch all patients
  Future<List<PatientRecord>> fetchAll() async {
    final snap = await _patients.orderBy('collectedAt', descending: true).get();

    return snap.docs
        .map((doc) => PatientRecord.fromMap({'id': doc.id, ...doc.data()}))
        .toList();
  }

  // Create or update patient
  Future<void> upsertPatient(PatientRecord patient) async {
    await _patients.doc(patient.id).set(patient.toMap());
  }

  // update diagnosis only
  Future<void> updateDiagnosis(
    String patientId,
    Map<String, dynamic> diagnosis,
  ) async {
    await _patients.doc(patientId).update({
      'diagnosis': diagnosis,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // optional realtime stream
  Stream<List<PatientRecord>> streamPatients() {
    return _patients
        .orderBy('collectedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => PatientRecord.fromMap({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }
}
