import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:sqflite/sqflite.dart';

class LocalDbService {
  static final LocalDbService _instance = LocalDbService._internal();
  factory LocalDbService() => _instance;
  LocalDbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'skinapp.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
                CREATE TABLE patients (
                    id TEXT PRIMARY KEY,
                    data TEXT NOT NULL,
                    synced INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL
                )
            ''');
      },
    );
  }

  // --- WRITE ----------------------
  Future<void> upsertPatient(PatientRecord p, {bool synced = false}) async {
    final d = await db;
    await d.insert('patients', {
      'id': p.id,
      'data': jsonEncode(p.toMap()),
      'synced': synced ? 1 : 0,
      'created_at': p.collectedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markSynced(String id) async {
    final d = await db;
    await d.update('patients', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // --- Read ----------------------
  Future<List<PatientRecord>> getAllPatients() async {
    final d = await db;
    final rows = await d.query('patients', orderBy: 'created_at DESC');
    final result = <PatientRecord>[];
    for (final row in rows) {
      try {
        final map = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        result.add(PatientRecord.fromMap(map));
      } catch (e) {
        // skip corrupt rows and avoid crash
        debugPrint('LocalDbService: skipping corruppt row ${row['id']}: $e');
      }
    }
    return result;
  }

  Future<List<PatientRecord>> getUnsynced() async {
    final d = await db;
    final rows = await d.query(
      'patients',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    final result = <PatientRecord>[];
    for (final row in rows) {
      try {
        final map = jsonEncode(row['data'] as String) as Map<String, dynamic>;
        result.add(PatientRecord.fromMap(map));
      } catch (_) {}
    }
    return result;
  }
}
