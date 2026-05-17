import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:skinapp2/services/firestore_service.dart';
import 'package:skinapp2/services/local_db_service.dart';

class SyncService {
  final LocalDbService _local;
  final FirestoreService _remote = FirestoreService();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = false;

  SyncService(this._local);

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final nowOnline = results.any((r) => r != ConnectivityResult.none);
      if (nowOnline && !_online) {
        _online = true;
        await pushUnsynced();
      } else if (!nowOnline) {
        _online = false;
      }
    });
  }

  void dispose() => _sub?.cancel();

  // push all unsynced local records to firestore (+photos)
  // returns number successfully pushed
  Future<int> pushUnsynced() async {
    final pending = await _local.getUnsynced();
    if (pending.isEmpty) return 0;
    int pushed = 0;
    for (final record in pending) {
      try {
        // upsertPatient handles photo upload internally
        await _remote.upsertPatient(record);
        await _local.markSynced(record.id);
        pushed++;
      } catch (e) {
        debugPrint('SyncService: failed to push ${record.id}: $e');
        // Leave as unsynced; will retry next reconnection
      }
    }
    debugPrint('SyncService: pushed $pushed/${pending.length} records');
    return pushed;
  }
}
