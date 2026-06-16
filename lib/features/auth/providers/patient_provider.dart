// -- Patient State -----
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/mock_data.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/services/firestore_service.dart';
import 'package:skinapp2/services/geocoding_retry_service.dart';
import 'package:skinapp2/services/local_db_service.dart';
import 'package:skinapp2/services/sync_service.dart';

class PatientState {
  final List<PatientRecord> records;
  final List<PatientRecord> allLocal;
  final bool loading;
  final String? error;
  final bool online;
  final int unsyncedCount;

  const PatientState({
    this.records = const [],
    this.allLocal = const [],
    this.loading = false,
    this.error,
    this.online = true,
    this.unsyncedCount = 0,
  });

  PatientState copyWith({
    List<PatientRecord>? records,
    List<PatientRecord>? allLocal,
    bool? loading,
    String? error,
    bool clearError = false,
    bool? online,
    int? unsyncedCount,
  }) {
    return PatientState(
      records: records ?? this.records,
      allLocal: allLocal ?? this.allLocal,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      online: online ?? this.online,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
    );
  }
}

// -- Patient Notifier -------------
class PatientNotifier extends StateNotifier<PatientState> {
  final LocalDbService _local = LocalDbService();
  final FirestoreService _remote = FirestoreService();
  final SyncService _sync = SyncService(LocalDbService());
  final AccessRole _role;
  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  late final VoidCallback _geocodeCallback;

  PatientNotifier(this._role) : super(const PatientState()) {
    _init();
  }

  Future<void> refreshLocal() => _refreshFromLocal();

  Future<void> _init() async {
    state = state.copyWith(loading: true);

    // 1. load from sqlite immediately (works offline)
    await _refreshFromLocal();

    // 2. check current connectivity
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    state = state.copyWith(online: online);

    // 3. if online, pull from Firestore and sync pending
    if (online) await _fetchRemote();
    _sync.start();

    // register this notifier's refresh as a listener
    // using a named reference so we can remove it in dispose()
    _geocodeCallback = () async {
      debugPrint('PatientNotifier($_role): geocode callback fired');
      await _refreshFromLocal();
      debugPrint(
        'PatientNotifier($_role): refreshed - '
        'first  community = "${state.records.isNotEmpty ? state.records.first.community : "none"}"',
      );
    };
    GeocodingRetryService().addListener(_geocodeCallback);

    // tell geocoding retry service to call refreshLocal()
    // after each successful reverse geocode
    GeocodingRetryService().start(
      onResolved: () async {
        await _refreshFromLocal();
        debugPrint('PatientNotifier: community resolved, UI refreshed');
      },
    );

    // 4. react to future connectivity changes
    _connectSub = Connectivity().onConnectivityChanged.listen((results) async {
      final nowOnline = results.any((r) => r != ConnectivityResult.none);
      state = state.copyWith(online: nowOnline);
      if (nowOnline) {
        await _sync.pushUnsynced();
        await _fetchRemote();
        //await _refreshFromLocal();
      }
    });
  }

  // load from local SQLite
  Future<void> _refreshFromLocal() async {
    final all = await _local.getAllPatients();
    final synced = await _local.getSyncedPatients();
    final unsynced = await _local.getUnsynced();

    // role-based visibility
    final visible = _role.isCollector ? all : synced;

    state = state.copyWith(
      allLocal: all,
      records: visible,
      unsyncedCount: unsynced.length,
      loading: false,
    );
  }

  // pull from firestore
  Future<void> _fetchRemote() async {
    try {
      final remote = await _remote.fetchAll();

      for (final r in remote) {
        await _local.upsertPatient(r, synced: true);
      }
      await _refreshFromLocal();

      state = state.copyWith(clearError: true);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      debugPrint('PatientNotifier._fetchRemote error: $e');
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

  Future<bool> addRecord(
    PatientRecord record, {
    bool needsGeocoding = false,
  }) async {
    try {
      // Save locally first (works offline)
      await _local.upsertPatient(
        record,
        synced: false,
        needsGeocoding: needsGeocoding,
      );
      // state = state.copyWith(records: [record, ...state.records]);
      await _refreshFromLocal();

      if (state.online) {
        await _remote.upsertPatient(record);
        await _local.markSynced(record.id);

        // re-fetch the record from Firestore to get the server-set receivedAt
        // then update the local sqlite copy
        try {
          final doc = await FirebaseFirestore.instance
              .collection('patients')
              .doc(record.id)
              .get();
          if (doc.exists && doc.data() != null) {
            final updated = PatientRecord.fromMap({
              'id': doc.id,
              ...doc.data()!,
            });
            await _local.upsertPatient(
              updated,
              synced: true,
              needsGeocoding: needsGeocoding,
            );
          } else {
            await _local.markSynced(record.id);
          }
        } catch (_) {
          await _local.markSynced(record.id);
        }
        // increment collector's record count in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(record.collectorId)
            .update({'recordCount': FieldValue.increment(1)});
        await _refreshFromLocal();
      }

      // await _refreshFromLocal();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('PatientNotifier.addRecord error: $e');
      return false;
    }
  }

  Future<bool> addDiagnosis(String patientId, Diagnosis diagnosis) async {
    try {
      // TODO: Firestore update
      final existing = state.allLocal.firstWhere((p) => p.id == patientId);
      final updated = PatientRecord(
        id: existing.id,
        idNumber: existing.idNumber,
        locationCoords: existing.locationCoords,
        fullName: existing.fullName,
        dateOfBirth: existing.dateOfBirth,
        phone: existing.phone,
        sex: existing.sex,
        emergencyName: existing.emergencyName,
        emergencyContact: existing.emergencyContact,
        photoUrls: existing.photoUrls,
        clinicalNotes: existing.clinicalNotes,
        collectorId: existing.collectorId,
        facilityName: existing.facilityName,
        collectedAt: existing.collectedAt,
        updatedAt: DateTime.now(),
        diagnosis: diagnosis,
      );

      await _local.upsertPatient(updated, synced: false);

      if (state.online) {
        await _remote.updateDiagnosis(patientId, diagnosis.toMap());
        await _local.markSynced(patientId);
      }

      // increment the physician's diagnosis count
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(diagnosis.physicianId)
            .set({
              'diagnosisCount': FieldValue.increment(1),
            }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('diagnosisCount increment failed: $e');
      }

      await _refreshFromLocal();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      debugPrint('PatientNotifier.addDiagnosis error: $e');
      return false;
    }
  }

  // manual sync trigger
  Future<void> syncNow() async {
    if (!state.online) return;
    await _sync.pushUnsynced();
    await _fetchRemote();
    await _refreshFromLocal();
    debugPrint('SyncNow: pushed new records');
  }

  // Search/filter helpers
  List<PatientRecord> search(String query, {bool syncedOnly = false}) {
    final pool = syncedOnly ? state.records : state.records;
    if (query.isEmpty) return pool;
    final q = query.toLowerCase();
    return pool
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
    // unregister from geocoding servicee to avoid memory leaks
    GeocodingRetryService().removeListener(_geocodeCallback);
    super.dispose();
  }
}

// -- Providers -------------
final patientProvider =
    StateNotifierProvider.family<PatientNotifier, PatientState, AccessRole>(
      (ref, role) => PatientNotifier(role),
    );

final pendingPatientsProvider =
    Provider.family<List<PatientRecord>, AccessRole>(
      (ref, role) => ref
          .watch(patientProvider(role))
          .records
          .where((p) => !p.hasDiagnosis)
          .toList(),
    );

final diagnosedPatientsProvider =
    Provider.family<List<PatientRecord>, AccessRole>(
      (ref, role) => ref
          .watch(patientProvider(role))
          .records
          .where((p) => p.hasDiagnosis)
          .toList(),
    );

final isOnlineProvider = Provider.family<bool, AccessRole>(
  (ref, role) => ref.watch(patientProvider(role)).online,
);

final unsyncedCountProvider = Provider.family<int, AccessRole>(
  (ref, role) => ref.watch(patientProvider(role)).unsyncedCount,
);
