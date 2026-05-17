import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:skinapp2/models/patient.dart';

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // upload photos, return cloud urls
  // take local file paths stored in clinicalNotes json
  // uploads each to Firebase Storage, returns urls
  Future<List<String>> uploadPhotos(
    String patientId,
    List<String> localPaths,
  ) async {
    final urls = <String>[];
    for (int i = 0; i < localPaths.length; i++) {
      final file = File(localPaths[i]);
      if (!file.existsSync()) {
        debugPrint('FirestoreService: photo not found at ${localPaths[i]}');
        continue;
      }
      try {
        final ref = _storage
            .ref()
            .child('patients')
            .child(patientId)
            .child('photo_$i.jpg');

        final task = await ref.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final url = await task.ref.getDownloadURL();
        urls.add(url);
        debugPrint('FirestoreService: uploaded photo $i -> $url');
      } catch (e) {
        debugPrint('FirestoreService: photo $i upload failed: $e');
      }
    }
    return urls;
  }

  CollectionReference<Map<String, dynamic>> get _patients =>
      _db.collection('patients');

  // Create or update patient + photo upload
  Future<void> upsertPatient(PatientRecord patient) async {
    // 1. extract local photo paths from clinicalNotes JSON
    final clinical = _parseJson(patient.clinicalNotes);
    final localPaths = (clinical['localPhotoPaths'] as List? ?? [])
        .cast<String>()
        .where((p) => p.isNotEmpty)
        .toList();

    List<String> cloudUrls = List<String>.from(patient.photoUrls);

    // 2. upload any localphotos that haven't been
    if (localPaths.isNotEmpty) {
      final newUrls = await uploadPhotos(patient.id, localPaths);
      cloudUrls = [...cloudUrls, ...newUrls];

      // 3. clear local paths now that they're uploaded, store cloud urls
      clinical['localPhotoPaths'] = [];
      clinical['photoUrls'] = cloudUrls;
    }

    // 4. build the final map with cloud url in photourl field
    final map = patient.toMap();
    map['photoUrls'] = cloudUrls;
    map['clinicalNotes'] = jsonEncode(clinical);

    await _patients.doc(patient.id).set(map);
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

  // Fetch all patients
  Future<List<PatientRecord>> fetchAll() async {
    final snap = await _patients.orderBy('collectedAt', descending: true).get();
    final result = <PatientRecord>[];
    for (final doc in snap.docs) {
      try {
        result.add(PatientRecord.fromMap({'id': doc.id, ...doc.data()}));
      } catch (e) {
        debugPrint('FirestoreService.fetchall: skipping ${doc.id}: $e');
      }
    }
    return result;
  }

  // fetch users
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final snap = await _db.collection('users').get();
    return snap.docs.map((d) => {'uid': d.id, ...d.data()}).toList();
  }

  // delete user (admin only)
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    // nb: this deletes from firestore only
    // deleting from firebase auth requires admin sdk(server-side)
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

  Map<String, dynamic> _parseJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
