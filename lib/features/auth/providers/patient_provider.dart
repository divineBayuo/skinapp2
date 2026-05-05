// -- Patient State -----
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/mock_data.dart';
import 'package:skinapp2/services/local_db_service.dart';
import 'package:skinapp2/services/sync_service.dart';

class PatientState {
  final List<PatientRecord> records;
  final bool loading;
  final String? error;
  final bool online;

  const PatientState({
    this.records = const [],
    this.loading = false,
    this.error,
    this.online = true,
  });

  PatientState copyWith({
    List<PatientRecord>? records,
    bool? loading,
    String? error,
    bool? online,
  }) {
    return PatientState(
      records: records ?? this.records,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      online: online ?? this.online,
    );
  }
}

// -- Patient Notifier -------------
class PatientNotifier extends StateNotifier<PatientState> {
  final LocalDbService _local = LocalDbService();
  final SyncService _sync = SyncService(LocalDbService());
  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  PatientNotifier() : super(const PatientState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(loading: true);

    // 1. load from sqlite immediately (works offline)
    final local = await _local.getAllPatients();
    state = state.copyWith(records: local, loading: false);

    // 2. check current connectivity
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(online: online);

    // 3. if online, pull from Firestore and sync pending
    if (online) await _fetchRemote();
    _sync.start();

    // 4. react to future connectivity changes
    _connectSub = Connectivity().onConnectivityChanged.listen((results) async {
      final nowOnline = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(online: nowOnline);
      if (nowOnline) await _fetchRemote();
    });
  }

  Future<void> _fetchRemote() async {
    try {
      // --- TODO: replace this with Firestorm stream
      // final snap = await FirebaseFirestore.instance
      //    .collection('patients')
      //    .orderBy('collectedAt', descending: true)
      //    .get();
      // final remote = snap.docs
      //    .map((d) => PatientRecord.fromMap({'id': d.id, ...d.data()}))
      //    .toList();
      //
      // // Upsert remote records locally and mark them synced
      // for (final r in remote) await _local.upsertPatient(r, synced: true);
      // state = state.copyWith(records: remote);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
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
      // Save locally first (works offline)
      await _local.upsertPatient(record, synced: !state.online);
      state = state.copyWith(records: [record, ...state.records]);

      if (state.online) {
        // -- TODO: push to firestore
        // await FirebaseFirestore.instance
        //    .collection('patients')
        //    .doc(record.id)
        //    .set(record.toMap());
        await _local.markSynced(record.id);
      }
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
        if (p.id != patientId) return p;
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
      }).toList();

      final record = updated.firstWhere((p) => p.id == patientId);
      await _local.upsertPatient(record, synced: false);
      state = state.copyWith(records: updated);

      if (state.online) {
        // -- TODO: Firestore update ------------
        // await FirebaseFirestore.instance
        //    .collection('patients')
        //    .doc(patientId)
        //    .update({'diagnosis':diagnosis.toMap(), 'updatedAt': ...});
        await _local.markSynced(patientId);
      }
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
              p.locationCoords.toLowerCase().contains(q),
        )
        .toList();
  }

  List<PatientRecord> filterByDate(DateTime date) => state.records
      .where(
        (p) =>
            p.collectedAt.year == date.year &&
            p.collectedAt.month == date.month &&
            p.collectedAt.day == date.day,
      )
      .toList();

  @override
  void dispose() {
    _connectSub?.cancel();
    _sync.dispose();
    super.dispose();
  }
}

// -- Providers -------------
final patientProvider = StateNotifierProvider<PatientNotifier, PatientState>(
  (ref) => PatientNotifier(),
);

final pendingPatientsProvider = Provider<List<PatientRecord>>(
  (ref) =>
      ref.watch(patientProvider).records.where((p) => !p.hasDiagnosis).toList(),
);

final diagnosedPatientsProvider = Provider<List<PatientRecord>>(
  (ref) =>
      ref.watch(patientProvider).records.where((p) => p.hasDiagnosis).toList(),
);

final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(patientProvider).online,
);
