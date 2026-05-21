import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:skinapp2/core/theme/app_theme.dart';

class _MapPatient {
  final String name;
  final String idNumber;
  final String facility;
  final bool hasDiagnosis;
  final LatLng coords;

  const _MapPatient({
    required this.name,
    required this.idNumber,
    required this.facility,
    required this.hasDiagnosis,
    required this.coords,
  });
}

class PatientMapScreen extends StatefulWidget {
  const PatientMapScreen({super.key});

  @override
  State<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends State<PatientMapScreen> {
  final _mapCtrl = MapController();
  bool _loading = true;
  String? _error;
  List<_MapPatient> _patients = [];
  _MapPatient? _selected;

  // Default centre: Ghana
  static const _ghana = LatLng(7.9465, -1.0232);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('patients')
          .get();

      final result = <_MapPatient>[];
      for (final doc in snap.docs) {
        final d = doc.data();
        final raw = d['locationCoords'] as String? ?? '';
        final ll = _parse(raw);
        if (ll == null) continue; // skip records with no/bad coords

        result.add(
          _MapPatient(
            name: d['fullName'] as String? ?? 'Unknown',
            idNumber: d['idNumber'] as String? ?? '',
            facility: d['facilityName'] as String? ?? '-',
            hasDiagnosis: d['diagnosis'] != null,
            coords: ll,
          ),
        );
      }

      setState(() {
        _patients = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  LatLng? _parse(String raw) {
    // Expects "lat, lng"
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        title: Text('Patient Locations', style: t.titleMedium),
        actions: [
          // Refresh
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
          // fit all markers
          if (_patients.isNotEmpty)
            IconButton(
              onPressed: _fitAll,
              icon: const Icon(Icons.fit_screen_rounded),
            ),
        ],
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text('Failed to load map data'),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(fontSize: 12, color: AppColors.textMid),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : Stack(
              children: [
                // Map
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _patients.isNotEmpty
                        ? _patients.first.coords
                        : _ghana,
                    initialZoom: 7,
                    onTap: (_, __) => setState(() => _selected = null),
                  ),
                  children: [
                    // OpenStreetMap tiles
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.skinapp2',
                    ),

                    // Patient markers
                    MarkerLayer(
                      markers: _patients.map((p) {
                        final isDx = p.hasDiagnosis;
                        final color = isDx
                            ? AppColors.success
                            : Colors.orange.shade600;

                        return Marker(
                          point: p.coords,
                          width: 36,
                          height: 36,
                          child: GestureDetector(
                            onTap: () => setState(() => _selected = p),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isDx
                                    ? Icons.verified_rounded
                                    : Icons.person_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // legend
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendRow(
                          color: AppColors.success,
                          label: 'Diagnosed',
                        ),
                        const SizedBox(height: 6),
                        _LegendRow(
                          color: Colors.orange.shade600,
                          label: 'Pending',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_patients.length} total',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // selected patient card
                if (_selected != null)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: _PatientCard(
                      patient: _selected!,
                      onClose: () => setState(() => _selected = null),
                    ),
                  ),
              ],
            ),
    );
  }

  void _fitAll() {
    if (_patients.isEmpty) return;
    final lats = _patients.map((p) => p.coords.latitude);
    final lngs = _patients.map((p) => p.coords.longitude);
    final bounds = LatLngBounds(
      LatLng(
        lats.reduce((a, b) => a < b ? a : b),
        lngs.reduce((a, b) => a < b ? a : b),
      ),
      LatLng(
        lats.reduce((a, b) => a > b ? a : b),
        lngs.reduce((a, b) => a > b ? a : b),
      ),
    );
    _mapCtrl.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }
}

// small widgets
class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _PatientCard extends StatelessWidget {
  final _MapPatient patient;
  final VoidCallback onClose;
  const _PatientCard({required this.patient, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (patient.hasDiagnosis
                ? AppColors.success
                : Colors.orange.withOpacity(0.12)),
            child: Icon(
              patient.hasDiagnosis
                  ? Icons.verified_rounded
                  : Icons.hourglass_top_rounded,
              color: patient.hasDiagnosis
                  ? AppColors.success
                  : Colors.orange.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  patient.idNumber,
                  style: TextStyle(fontSize: 11, color: AppColors.textMid),
                ),
                Text(
                  patient.facility,
                  style: TextStyle(fontSize: 11, color: AppColors.textMid),
                ),
                Text(
                  '${patient.coords.latitude.toStringAsFixed(5)}, '
                  '${patient.coords.longitude.toStringAsFixed(5)}',
                  style: TextStyle(fontSize: 10, color: AppColors.textMid),
                ),
              ],
            ),
          ),
          // status chip
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      (patient.hasDiagnosis
                              ? AppColors.success
                              : Colors.orange.shade600)
                          .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  patient.hasDiagnosis ? 'Diagnosed' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: patient.hasDiagnosis
                        ? AppColors.success
                        : Colors.orange.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onClose,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMid,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
