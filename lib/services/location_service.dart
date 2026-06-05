import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final String coords; // lat, lng
  final String community; // reverse-geocoded locality

  const LocationResult({required this.coords, required this.community});
}

class LocationService {
  static final LocationService _i = LocationService._();
  factory LocationService() => _i;
  LocationService._();

  Future<LocationResult?> getCurrentLocation() async {
    // 1. Check service enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // 3. Get position
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    final coords =
        '${pos.latitude.toStringAsFixed(6)}, '
        '${pos.longitude.toStringAsFixed(6)}';

    // 4. reverse geocode to get community name
    String community = '';
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // build community string from most specific to broadcast
        // subLocality (neighbourhood) -> locality (town/city) -> subAdminArea
        community = [
          p.subLocality,
          p.locality,
          p.subAdministrativeArea,
        ].where((s) => s != null && s.isNotEmpty).join(', ');
      }
    } catch (e) {
      // reverse geocoding is best-effort - not fatal if it fails
      debugPrint('LocationService: reverse geocoding failed: $e');
    }
    return LocationResult(coords: coords, community: community);
  }

  // return coords as "lat, lng" string, or null or failure
  Future<String?> getCurrentCoords() async {
    final result = await getCurrentLocation();
    return result?.coords;
  }
}
