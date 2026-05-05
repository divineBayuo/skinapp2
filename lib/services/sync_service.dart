import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:skinapp2/services/local_db_service.dart';

class SyncService {
  final LocalDbService _local;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = false;

  SyncService(this._local);

  void start() {
    _sub = Connectivity().onConnectivityChanged.listen((results) async {
      final nowOnline = results.any((r) => r != ConnectivityResult.none);
      if (nowOnline && !_online) {
        _online = true;
        await _pushUnsynced();
      } else if (!nowOnline) {
        _online = false;
      }
    });
  }

  void dispose() => _sub?.cancel();

  Future<void> _pushUnsynced() async {
    final pending = await _local.getUnsynced();
    for (final record in pending) {
      try {
        // -- TODO: swap with real Firestore call
        // await FirebaseFirestore.instance
        //  .collection('patients')
        //  .doc(record.id)
        //  .set(record.toMap());
        await Future.delayed(const Duration(milliseconds: 100)); // to be removed after real call
        await _local.markSynced(record.id);
      } catch (_) {
        // Leave as unsynced; will retry next reconnection
      }
    }
  }

  /// Call once after checking connectivity at app start
  Future<void> syncNow() => _pushUnsynced();
}
