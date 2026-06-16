import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:skinapp2/services/firestore_service.dart';
import 'package:skinapp2/services/local_db_service.dart';

class GeocodingRetryService {
  static final GeocodingRetryService _i = GeocodingRetryService._();
  factory GeocodingRetryService() => _i;
  GeocodingRetryService._();

  final LocalDbService _local = LocalDbService();
  final FirestoreService _remote = FirestoreService();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _started = false;

  // using a list so multiple notifiers with different roles
  // can all be notified - each PatientNotifier registers
  // its own callback
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  // called after each successful geocode to enable providers refresh state
  VoidCallback? onGeocodeResolved;

  void start({VoidCallback? onResolved}) {
    onGeocodeResolved = onResolved;

    if (_started) return;
    _started = true;
    debugPrint('GeocodingRetryService: started');
    // retry immediately on startup (in case already online)
    _retryPending();

    // and every time connectivity is restored
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _retryPending();
      }
    });
  }

  void dispose() {
    _sub?.cancel();
    _listeners.clear();
    _started = false;
  }

  void _notifyListeners() {
    debugPrint(
      'GeocodingRetryService: notifying ${_listeners.length} listener(s)',
    );
    for (final cb in List<VoidCallback>.from(_listeners)) {
      cb();
    }
  }

  Future<void> _retryPending() async {
    final pending = await _local.getNeedsGeocoding();
    if (pending.isEmpty) {
      debugPrint('GeocodingRetryService: no pending records');
      return;
    }

    debugPrint(
      'GeocodingRetryService: ${pending.length} records need geocoding',
    );

    bool anyResolved = false;

    for (final record in pending) {
      if (record.locationCoords.isEmpty) continue;

      final community = await _geocode(record.locationCoords);
      if (community == null) {
        debugPrint('GeocodingRetryService: could not geocode ${record.id} '
        '(offline or failed)');
        continue; // still offline or failed
      }

      // update sqlite with the resolved community name
      await _local.markGeocoded(record.id, community);
      anyResolved = true;
      debugPrint(
        'GeocodingRetryService: ✅ SQLite updated — '
        '${record.id} community -> $community',
      );

      // if the record is already synced to Firestore, update it there too
      final syncedIds = (await _local.getSyncedPatients())
          .map((p) => p.id)
          .toSet();
      debugPrint(
        'GeocodingRetryService: synced=${syncedIds.contains(record.id)}',
      );
      if (syncedIds.contains(record.id)) {
        try {
          await _remote.updateCommunity(record.id, community);
          debugPrint(
            'GeocodingRetryService: ✅ Firestore updated — '
            '${record.id} community = "$community"',
          );
        } catch (e) {
          debugPrint('GeocodingRetryService: ❌ Firestore update failed: $e');
        }
      }
      // if not yet synced, SyncService will push the updated record
      // (including the now-resolved community) when it runs next
    }

    // notify providers to refresh
    if (anyResolved) {
      debugPrint('GeocodingRetryService: calling onGeocodeResolved callback');
      debugPrint(
        'GeocodingRetryService: callback is ${onGeocodeResolved == null ? "NULL ❌" : "set ✅"}',
      );
      onGeocodeResolved?.call();
      _notifyListeners();
    }
  }

  // parse 'lat, lng' string and reverse geocode
  Future<String?> _geocode(String coords) async {
    try {
      final parts = coords.split(',');
      if (parts.length != 2) return null;
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat == null || lng == null) return null;

      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      final community = [
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      return community.isEmpty ? null : community;
    } catch (_) {
      return null; // network unavailable - caller will skip
    }
  }
}
