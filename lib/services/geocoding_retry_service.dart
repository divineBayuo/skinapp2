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

  void start() {
    // retry immediately on startup (in case already online)
    _retryPending();

    // and every time connectivity is restored
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _retryPending();
      }
    });
  }

  void dispose() => _sub?.cancel();

  Future<void> _retryPending() async {
    final pending = await _local.getNeedsGeocoding();
    if (pending.isEmpty) return;

    debugPrint(
      'GeocodingRetryService: ${pending.length} records need geocoding',
    );

    for (final record in pending) {
      if (record.locationCoords.isEmpty) continue;

      final community = await _geocode(record.locationCoords);
      if (community == null) continue; // still offline or failed

      // update sqlite with the resolved community name
      await _local.markGeocoded(record.id, community);
      debugPrint('GeocodingRetryService: resolved ${record.id} -> $community');

      // if the record is already synced to Firestore, update it there too
      final isSynced = (await _local.getSyncedPatients()).any(
        (p) => p.id == record.id,
      );
      if (isSynced) {
        try {
          await _remote.updateCommunity(record.id, community);
        } catch (e) {
          debugPrint('GeocodingRetryService: Firestore update failed: $e');
        }
      }
      // if not yet synced, SyncService will push the updated record
      // (including the now-resolved community) when it runs next
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
