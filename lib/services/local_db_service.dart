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
      version: 2,
      onCreate: (db, _) => db.execute('''
                CREATE TABLE patients (
                    id TEXT PRIMARY KEY,
                    data TEXT NOT NULL,
                    synced INTEGER NOT NULL DEFAULT 0,
                    needs_geocoding INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL
                )
            '''),
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Existing installs: add new column
          await db.execute(
            'ALTER TABLE patients ADD COLUMN needs_geocoding INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
  }

  PatientRecord? _tryParse(Map<String, Object?> row) {
    try {
      return PatientRecord.fromMap(
        jsonDecode(row['data'] as String) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('LocalDbService: corrupt row ${row['id']}: $e');
      return null;
    }
  }

  // --- WRITE ----------------------
  Future<void> upsertPatient(
    PatientRecord p, {
    bool synced = false,
    bool needsGeocoding = false,
  }) async {
    final d = await db;

    // check if the row already exists and preserve needs_geocoding
    // if it was previously flagged, don't let a remote fetch clear it
    final existing = await d.query(
      'patients',
      columns: ['needs_geocoding'],
      where: 'id=?',
      whereArgs: [p.id],
    );

    // if a row already exists and was flagged for geocoding
    // keep that flag unless the caller explicitly passes needsGeocoding
    // or the community has now been resolved (non-empty)
    final existingNeedsGeocoding = existing.isNotEmpty
        ? (existing.first['needs_geocoding'] as int? ?? 0) == 1
        : false;

    final finalNeedsGeocoding = p.community.isNotEmpty
        ? false   // community resolved, clear flag
        : (needsGeocoding || existingNeedsGeocoding);   // preserve if set

    await d.insert('patients', {
      'id': p.id,
      'data': jsonEncode(p.toMap()),
      'synced': synced ? 1 : 0,
      'needs_geocoding': finalNeedsGeocoding ? 1 : 0,
      'created_at': p.collectedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> markSynced(String id) async {
    final d = await db;
    await d.update('patients', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markGeocoded(String id, String community) async {
    final d = await db;
    // read current data, update community, write back
    final rows = await d.query('patients', where: 'id=?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final map =
        jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
    map['community'] = community;
    await d.update(
      'patients',
      {'data': jsonEncode(map), 'needs_geocoding': 0},
      where: 'id=?',
      whereArgs: [id],
    );
  }

  // --- Read ----------------------
  Future<List<PatientRecord>> getAllPatients() async {
    final d = await db;
    final rows = await d.query('patients', orderBy: 'created_at DESC');
    /* final result = <PatientRecord>[];
    for (final row in rows) {
      try {
        final map = jsonDecode(row['data'] as String) as Map<String, dynamic>;
        result.add(PatientRecord.fromMap(map));
      } catch (e) {
        // skip corrupt rows and avoid crash
        debugPrint('LocalDbService: skipping corrupt row ${row['id']}: $e');
      }
    }
    return result; */
    return rows.map(_tryParse).whereType<PatientRecord>().toList();
  }

  Future<List<PatientRecord>> getSyncedPatients() async {
    final d = await db;
    final rows = await d.query(
      'patients',
      where: 'synced=1',
      orderBy: 'created_at DESC',
    );
    return rows.map(_tryParse).whereType<PatientRecord>().toList();
  }

  Future<List<PatientRecord>> getUnsynced() async {
    final d = await db;
    final rows = await d.query(
      'patients',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
    /* final result = <PatientRecord>[];
    for (final row in rows) {
      try {
        final map = jsonEncode(row['data'] as String) as Map<String, dynamic>;
        result.add(PatientRecord.fromMap(map));
      } catch (_) {}
    }
    return result; */
    return rows.map(_tryParse).whereType<PatientRecord>().toList();
  }

  // records whose community name still needs geocoding
  Future<List<PatientRecord>> getNeedsGeocoding() async {
    final d = await db;
    final rows = await d.query(
      'patients',
      where: 'needs_geocoding = 1',
      orderBy: 'created_at ASC',
    );
    return rows.map(_tryParse).whereType<PatientRecord>().toList();
  }
}
