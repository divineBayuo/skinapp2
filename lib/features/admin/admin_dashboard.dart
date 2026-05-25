// models
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/services/firestore_service.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/live_clock.dart';

class _AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String facility;
  final DateTime? lastSeen;
  final int recordCount;

  const _AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.facility,
    required this.recordCount,
    this.lastSeen,
  });

  factory _AppUser.fromMap(Map<String, dynamic> m) => _AppUser(
    uid: m['uid'] as String? ?? '',
    name: m['fullName'] as String? ?? 'Unknown',
    email: m['email'] as String? ?? '',
    role: m['role'] as String? ?? 'collector',
    facility: m['facilityName'] as String? ?? '-',
    recordCount: m['recordCount'] as int? ?? 0,
    lastSeen: m['lastSeen'] != null
        ? DateTime.tryParse(m['lastSeen'] as String)
        : null,
  );
}

// -- patient summary ----------
class _PatientSummary {
  final String id;
  final String fullName;
  final String idNumber;
  final String collectorId;
  final String facility;
  final String collectedAt;
  final bool hasDiagnosis;

  const _PatientSummary({
    required this.id,
    required this.fullName,
    required this.idNumber,
    required this.collectorId,
    required this.facility,
    required this.collectedAt,
    required this.hasDiagnosis,
  });

  factory _PatientSummary.fromMap(String id, Map<String, dynamic> m) =>
      _PatientSummary(
        id: id,
        fullName: m['fullName'] as String? ?? 'Unknown',
        idNumber: m['idNumber'] as String? ?? id,
        collectorId: m['collectorId'] as String? ?? '',
        facility: m['facilityName'] as String? ?? '-',
        collectedAt: m['collectedAt'] as String? ?? '',
        hasDiagnosis: m['diagnosis'] != null,
      );

  String get formattedDate {
    try {
      final d = DateTime.parse(collectedAt);
      const mo = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${d.day} ${mo[d.month - 1]} ${d.year}';
    } catch (_) {
      return collectedAt;
    }
  }
}

class _Stats {
  final int total;
  final int diagnosed;
  final int pending;
  final Map<String, int> bySuspicion;
  final Map<String, int> byFacility;
  final Map<String, int> byLesionType;
  final Map<String, int> byDetectionMode;
  final Map<String, int> bySex;
  const _Stats({
    required this.total,
    required this.diagnosed,
    required this.pending,
    required this.bySuspicion,
    required this.byFacility,
    required this.byLesionType,
    required this.byDetectionMode,
    required this.bySex,
  });
}

// --- Screen ----------------------------------
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _loading = true;
  bool _exportingStats = false;
  bool _clearingDb = false;
  String? _error;

  List<_AppUser> _collectors = [];
  List<_AppUser> _physicians = [];
  List<_AppUser> _researchers = [];
  List<_PatientSummary> _patients = [];
  _Stats? _stats;

  // search for the records tab
  final _recordSearchCtrl = TextEditingController();
  String _recordFilter = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    _recordSearchCtrl.addListener(
      () =>
          setState(() => _recordFilter = _recordSearchCtrl.text.toLowerCase()),
    );
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _recordSearchCtrl.dispose();
    super.dispose();
  }

  // load all data
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = FirebaseFirestore.instance;

      // users
      final userDocs = await db.collection('users').get();
      final users = userDocs.docs
          .map((d) => _AppUser.fromMap({'uid': d.id, ...d.data()}))
          .toList();

      // patients
      final patientDocs = await db.collection('patients').get();
      final patients = patientDocs.docs.map((d) => d.data()).toList();
      final patientList = patientDocs.docs
          .map((d) => _PatientSummary.fromMap(d.id, d.data()))
          .toList();

      // build stats
      int diagnosed = 0;
      final bySuspicion = <String, int>{};
      final byFacility = <String, int>{};
      final byLesionType = <String, int>{};
      final byDetection = <String, int>{};
      final bySex = <String, int>{};

      for (final p in patients) {
        if (p['diagnosis'] != null) diagnosed++;

        // sex
        final sex = p['sex'] as String? ?? 'Unknown';
        bySex[sex] = (bySex[sex] ?? 0) + 1;

        // facility
        final fac = p['facilityName'] as String? ?? 'Unknown';
        byFacility[fac] = (byFacility[fac] ?? 0) + 1;

        // clinical notes json fields
        final clinical = _parseJson(p['clinicalNotes'] as String? ?? '{}');

        // suspicions
        for (final s in (clinical['clinicalSuspicion'] as List? ?? [])) {
          final key = s.toString();
          bySuspicion[key] = (bySuspicion[key] ?? 0) + 1;
        }

        // lesion types
        for (final lt in (clinical['lesionTypes'] as List? ?? [])) {
          final key = lt.toString();
          byLesionType[key] = (byLesionType[key] ?? 0) + 1;
        }

        // detection mode
        final mode = clinical['modeOfDetection'] as String? ?? 'Unknown';
        byDetection[mode] = (byDetection[mode] ?? 0) + 1;
      }

      setState(() {
        _collectors = users.where((u) => u.role == 'collector').toList();
        _physicians = users.where((u) => u.role == 'physician').toList();
        _researchers = users.where((u) => u.role == 'researcher').toList();
        _patients = patientList;
        _stats = _Stats(
          total: patients.length,
          diagnosed: diagnosed,
          pending: patients.length - diagnosed,
          bySuspicion: bySuspicion,
          byFacility: byFacility,
          byLesionType: byLesionType,
          byDetectionMode: byDetection,
          bySex: bySex,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // delete single patient
  Future<void> _deletePatient(_PatientSummary patient) async {
    final confirm = await _confirmDialog(
      title: 'Delete Patient Record',
      message:
          'Permanently delete the record for '
          '${patient.fullName} (${patient.idNumber})?\n\n'
          'This will also remove any associated photos from storage. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (confirm != true) return;

    try {
      await FirestoreService().deletePatient(patient.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.fullName} deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // clear entire database
  Future<void> _clearDatabase() async {
    // double confirmation for nuclear action
    final confirm1 = await _confirmDialog(
      title: 'Clear Entire Database',
      message:
          'This will permanently delete ALL ${_patients.length} patient '
          'records and their photos from database.\n\n'
          'User accounts will NOT be deleted.\n\n'
          'This action CANNOT be undone.',
      confirmLabel: 'Continue',
      destructive: true,
    );

    if (confirm1 != true) return;

    final confirm2 = await _confirmDialog(
      title: 'Are you absolutely sure?',
      message:
          'Type-confirm: you are about to wipe ALL patient data. '
          'This is irreversible.',
      confirmLabel: 'Yes, delete everything',
      destructive: true,
    );

    if (confirm2 != true) return;

    setState(() => _clearingDb = true);
    try {
      final count = await FirestoreService().clearAllPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count records deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clear failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _clearingDb = false);
    }
  }

  // delete user
  Future<void> _deleteUser(_AppUser user) async {
    final confirm = await _confirmDialog(
      title: 'Remove User',
      message:
          'Remove ${user.name} (${user.role}) from the system?\n\n'
          'Their collected records will remain in the database.',
      confirmLabel: 'Remove',
      destructive: true,
    );

    if (confirm != true) return;

    try {
      await FirestoreService().deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} removed.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // reusable confirm dialog
  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (destructive)
            Icon(Icons.warning_rounded, color: Colors.red.shade600, size: 20),
          if (destructive) const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(fontSize: 13, color: AppColors.textMid),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? Colors.red : AppColors.navy,
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  // export stats pdf
  Future<void> _exportStatsPdf() async {
    if (_stats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No statistics to export yet.')),
      );
      return;
    }
    setState(() => _exportingStats = true);
    try {
      final file = await _buildStatsPdf(_stats!);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'SkinApp - Statistics Report');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportingStats = false);
    }
  }

  Future<File> _buildStatsPdf(_Stats stats) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    const month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final date = '${now.day} ${month[now.month - 1]} ${now.year}';

    // helper: section title
    pw.Widget _title(String text) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF0D3C6E),
        ),
      ),
    );

    // helper: horizontal bar row
    pw.Widget _bar(String label, int count, int total) {
      final pct = total == 0 ? 0.0 : count / total;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  '$count',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Stack(
              children: [
                pw.Container(
                  height: 6,
                  color: const PdfColor.fromInt(0xFFE8EDF2),
                ),
                pw.Container(
                  height: 6,
                  width: 400 * pct,
                  color: const PdfColor.fromInt(0xFF0D3C6E),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // sort helper
    List<MapEntry<String, int>> sorted(Map<String, int> m) =>
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final diagRate = stats.total == 0
        ? '-'
        : '${(stats.diagnosed / stats.total * 100).round()}%';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => [
          // header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SkinApp - Statistics Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF0D3C6E),
                ),
              ),
              pw.Text(
                'Generated: $date',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // summary cards
          pw.Row(
            children: [
              _summaryCard('Total Patients', '${stats.total}'),
              pw.SizedBox(width: 12),
              _summaryCard('Diagnosed', '${stats.diagnosed}'),
              pw.SizedBox(width: 12),
              _summaryCard('Pending', '${stats.pending}'),
              pw.SizedBox(width: 12),
              _summaryCard('Diagnosis Rate', diagRate),
              pw.SizedBox(width: 12),
            ],
          ),
          pw.SizedBox(height: 16),

          // users summary
          _title('USER SUMMARY'),
          pw.Row(
            children: [
              _summaryCard('Collectors', '${_collectors.length}'),
              pw.SizedBox(width: 12),
              _summaryCard('Physicians', '${_physicians.length}'),
              pw.SizedBox(width: 12),
              _summaryCard('Researchers', '${_researchers.length}'),
              pw.SizedBox(width: 12),
            ],
          ),

          // sex distribution
          _title('SEX DISTRIBUTION'),
          ...sorted(stats.bySex).map((e) => _bar(e.key, e.value, stats.total)),

          // mode of detection
          _title('MODE OF DETECTION'),
          ...sorted(
            stats.byDetectionMode,
          ).map((e) => _bar(e.key, e.value, stats.total)),

          // clinical suspicion
          _title('CLINICAL SUSPICION'),
          ...sorted(
            stats.bySuspicion,
          ).map((e) => _bar(e.key, e.value, stats.total)),

          // lesion types
          _title('LESION TYPES'),
          ...sorted(
            stats.byLesionType,
          ).map((e) => _bar(e.key, e.value, stats.total)),

          // records by facility
          _title('RECORDS BY FACILITY'),
          ...sorted(
            stats.byFacility,
          ).map((e) => _bar(e.key, e.value, stats.total)),

          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Text(
            'Confidential - SkinApp NTD Surveillance System',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/skinapp_statistics_$date.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _summaryCard(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0F4FA),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0D3C6E),
            ),
          ),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    ),
  );

  // delete user
  /*  Future<void> _deleteUser(_AppUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove User'),
        content: Text(
          'Remove ${user.name} (${user.role}) from the system?\n\n'
          'Their collected records will remian in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirestoreService().deleteUser(user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} removed'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove user: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  } */

  Map<String, dynamic> _parseJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // filtered patients
  List<_PatientSummary> get _filteredPatients {
    if (_recordFilter.isEmpty) return _patients;
    return _patients
        .where(
          (p) =>
              p.fullName.toLowerCase().contains(_recordFilter) ||
              p.idNumber.toLowerCase().contains(_recordFilter) ||
              p.facility.toLowerCase().contains(_recordFilter),
        )
        .toList();
  }

  // build
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Oversight', style: t.pageTitle),
                        const SizedBox(height: 2),
                        LiveClock(
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMid,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // map button - navigates instead of embed
                  Material(
                    color: AppColors.fieldBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.push('/admin/map'),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.map_rounded,
                          color: AppColors.navy,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // refresh
                  Material(
                    color: AppColors.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _loading ? null : _load,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                labelColor: AppColors.navy,
                unselectedLabelColor: AppColors.textMid,
                indicatorColor: AppColors.tealDeep,
                tabs: [
                  const Tab(text: 'Overview'),
                  const Tab(text: 'Statistics'),
                  Tab(text: 'Records (${_patients.length})'),
                  Tab(text: 'Collectors (${_collectors.length})'),
                  Tab(text: 'Physicians (${_physicians.length})'),
                  Tab(text: 'Researchers (${_researchers.length})'),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _ErrorView(error: _error!, onRetry: _load)
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _OverviewTab(stats: _stats!),
                        _StatisticsTab(stats: _stats!),
                        _RecordsTab(
                          patients: _filteredPatients,
                          searchCtrl: _recordSearchCtrl,
                          totalCount: _patients.length,
                          onDelete: _deletePatient,
                          onClearAll: _clearDatabase,
                          clearingDb: _clearingDb,
                        ),
                        _UserListTab(
                          users: _collectors,
                          emptyMessage: 'No collectors yet.',
                          onDelete: _deleteUser,
                        ),
                        _UserListTab(
                          users: _physicians,
                          emptyMessage: 'No physicians yet.',
                          onDelete: _deleteUser,
                        ),
                        _UserListTab(
                          users: _researchers,
                          emptyMessage: 'No researchers yet.',
                          onDelete: _deleteUser,
                        ),
                      ],
                    ),
            ),

            // Actions buttons row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // View/Collapse button (circular dark)
                  CircularActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.go('/home'),
                    size: 52,
                    bgColor: AppColors.fieldBg,
                    iconColor: AppColors.navy,
                  ),

                  // Export button (researcher)
                  const SizedBox(width: 16),
                  CircularActionButton(
                    icon: _exportingStats
                        ? Icons.hourglass_empty_rounded
                        : Icons.ios_share_rounded,
                    onTap: _exportingStats ? () {} : _exportStatsPdf,
                    bgColor: AppColors.saveRed,
                    size: 52,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final List<_PatientSummary> patients;
  final TextEditingController searchCtrl;
  final int totalCount;
  final void Function(_PatientSummary) onDelete;
  final VoidCallback onClearAll;
  final bool clearingDb;

  const _RecordsTab({
    required this.patients,
    required this.searchCtrl,
    required this.totalCount,
    required this.onDelete,
    required this.onClearAll,
    required this.clearingDb,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // search + clear-all header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              // search field
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: searchCtrl,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      hintStyle: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textMid,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // clear all button
              Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(30),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: clearingDb ? null : onClearAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: clearingDb
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade700,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_sweep_rounded,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Clear All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // count row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                patients.length == totalCount
                    ? '$totalCount records'
                    : '${patients.length} of $totalCount',
                style: TextStyle(fontSize: 12, color: AppColors.textMid),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List
        Expanded(
          child: patients.isEmpty
              ? Center(
                  child: Text(
                    'No records found.',
                    style: TextStyle(color: AppColors.textMid, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  itemBuilder: (_, i) => _RecordCard(
                    patient: patients[i],
                    onDelete: () => onDelete(patients[i]),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: patients.length,
                ),
        ),
      ],
    );
  }
}

// record card
class _RecordCard extends StatelessWidget {
  final _PatientSummary patient;
  final VoidCallback onDelete;

  const _RecordCard({required this.patient, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // status dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: patient.hasDiagnosis
                  ? AppColors.success
                  : Colors.orange.shade500,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (patient.hasDiagnosis
                              ? AppColors.success
                              : Colors.orange.shade500)
                          .withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  patient.hasDiagnosis ? 'Diagnosed' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: patient.hasDiagnosis
                        ? AppColors.success
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                patient.formattedDate,
                style: TextStyle(fontSize: 10, color: AppColors.textMid),
              ),
              const SizedBox(height: 6),

              // delete button
              Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_rounded,
                          size: 12,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- overview tab ---------------
class _OverviewTab extends StatelessWidget {
  final _Stats stats;
  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    final diagRate = stats.total == 0
        ? '-'
        : '${(stats.diagnosed / stats.total * 100).round()}%';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Patients',
                value: '${stats.total}',
                icon: Icons.people_rounded,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Diagnosed',
                value: '${stats.diagnosed}',
                icon: Icons.verified_rounded,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Pending',
                value: '${stats.pending}',
                icon: Icons.hourglass_top_rounded,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Diagnosis Rate',
                value: diagRate,
                icon: Icons.pie_chart_rounded,
                color: AppColors.tealDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _SectionLabel('Top Clinical Suspicions'),
        const SizedBox(height: 12),
        if (stats.bySuspicion.isEmpty)
          const _EmptyHint('No clinical suspicion data yet.')
        else
          ..._sorted(stats.bySuspicion).map(
            (e) => _BarRow(
              label: e.key,
              count: e.value,
              total: stats.total,
              color: AppColors.navy,
            ),
          ),
        const SizedBox(height: 20),
        _SectionLabel('Records by Facility'),
        const SizedBox(height: 12),
        if (stats.byFacility.isEmpty)
          const _EmptyHint('No facility data yet.')
        else
          ..._sorted(stats.byFacility).map(
            (e) => _BarRow(
              label: e.key,
              count: e.value,
              total: stats.total,
              color: AppColors.tealDeep,
            ),
          ),
      ],
    );
  }

  List<MapEntry<String, int>> _sorted(Map<String, int> m) =>
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

// ---Stats Tab------------------
class _StatisticsTab extends StatelessWidget {
  final _Stats stats;
  const _StatisticsTab({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // diagnosis status donut
        _SectionLabel('Diagnosis Status'),
        const SizedBox(height: 12),
        _DonutChart(
          segments: [
            _Segment('Diagnosed', stats.diagnosed, AppColors.success),
            _Segment('Pending', stats.pending, Colors.orange.shade600),
          ],
          total: stats.total,
        ),
        const SizedBox(height: 24),

        // sex distribution
        _SectionLabel('Sex Distribution'),
        const SizedBox(height: 12),
        _DonutChart(
          segments: stats.bySex.entries
              .map(
                (e) => _Segment(
                  e.key,
                  e.value,
                  e.key == 'Male' ? AppColors.navy : AppColors.tealDeep,
                ),
              )
              .toList(),
          total: stats.total,
        ),
        const SizedBox(height: 24),

        // Detection mode breakdown
        _SectionLabel('Mode of Detection'),
        const SizedBox(height: 12),
        if (stats.byDetectionMode.isEmpty)
          const _EmptyHint('No detection mode data yet')
        else
          ..._sorted(stats.byDetectionMode).map(
            (e) => _BarRow(
              label: e.key,
              count: e.value,
              total: stats.total,
              color: AppColors.navy,
            ),
          ),
        const SizedBox(height: 20),

        // Lesion type breakdown
        _SectionLabel('Lesion Types'),
        const SizedBox(height: 12),
        if (stats.byLesionType.isEmpty)
          const _EmptyHint('No lesion type data yet.')
        else
          ..._sorted(stats.byLesionType).map(
            (e) => _BarRow(
              label: e.key,
              count: e.value,
              total: stats.total,
              color: const Color(0xFF3C3489),
            ),
          ),
        const SizedBox(height: 20),

        // Clinical suspicion
        _SectionLabel('Clinical Suspicion'),
        const SizedBox(height: 12),
        if (stats.bySuspicion.isEmpty)
          const _EmptyHint('No clinical suspicion data yet.')
        else
          ..._sorted(stats.bySuspicion).map(
            (e) => _BarRow(
              label: e.key,
              count: e.value,
              total: stats.total,
              color: AppColors.tealDeep,
            ),
          ),

        // Location Map
        _SectionLabel('Patient Locations'),
        const SizedBox(height: 12),
        _MapNavigationCard(),
      ],
    );
  }

  List<MapEntry<String, int>> _sorted(Map<String, int> m) =>
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}

// map navigation card
class _MapNavigationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/admin/map'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Location Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View all collection points on an interactive map',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.65),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// user list tab
class _UserListTab extends StatelessWidget {
  final List<_AppUser> users;
  final String emptyMessage;
  final void Function(_AppUser) onDelete;
  const _UserListTab({
    required this.users,
    required this.emptyMessage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(color: AppColors.textMid, fontSize: 14),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) =>
          _UserCard(user: users[i], onDelete: () => onDelete(users[i])),
    );
  }
}

// user card
class _UserCard extends StatelessWidget {
  final _AppUser user;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.onDelete});

  Color get _roleColor {
    switch (user.role) {
      case 'physician':
        return const Color(0xFF3C3489);
      case 'researcher':
        return const Color(0xFF085041);
      default:
        return AppColors.navy;
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Never';
    const month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${month[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _roleColor.withOpacity(0.12),
            child: Text(
              user.name
                  .trim()
                  .split(' ')
                  .map((p) => p.isNotEmpty ? p[0] : '')
                  .take(2)
                  .join(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _roleColor,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(fontSize: 12, color: AppColors.textMid),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.local_hospital_rounded,
                      size: 11,
                      color: AppColors.textMid,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        user.facility,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMid,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Last seen: ${_fmt(user.lastSeen)}',
                  style: TextStyle(fontSize: 11, color: AppColors.textMid),
                ),
              ],
            ),
          ),

          // right column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _roleColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.role,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _roleColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${user.recordCount} records',
                style: TextStyle(fontSize: 11, color: AppColors.textMid),
              ),
              const SizedBox(height: 8),

              // delete button
              Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_remove_rounded,
                          size: 13,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// donut chart
class _Segment {
  final String label;
  final int value;
  final Color color;
  const _Segment(this.label, this.value, this.color);
}

class _DonutChart extends StatelessWidget {
  final List<_Segment> segments;
  final int total;
  const _DonutChart({required this.segments, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No data yet.',
            style: TextStyle(color: AppColors.textMid),
          ),
        ),
      );
    }
    return Row(
      children: [
        //chart
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            painter: _DonutPainter(segments: segments, total: total),
          ),
        ),
        const SizedBox(width: 20),
        // legend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: segments.map((s) {
              final pct = total == 0 ? 0 : (s.value / total * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.label} ($pct%)',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Text(
                      '${s.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: s.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Segment> segments;
  final int total;
  const _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final stroke = radius * 0.38;
    const gap = 0.03; // rad gap between segments

    double start = -3.14159 / 2;
    for (final seg in segments) {
      if (seg.value == 0) continue;
      final sweep = (seg.value / total) * 2 * 3.14159 - gap;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }

    // centre text
    final tp = TextPainter(
      text: TextSpan(
        text: '$total',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.total != total;
}

// shared widgets
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMid)),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final String label;
  final int count, total;
  final Color color;
  const _BarRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.fieldBg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.textNavy,
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text, style: TextStyle(fontSize: 13, color: AppColors.textMid)),
  );
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: Colors.redAccent,
        ),
        const SizedBox(height: 12),
        const Text(
          'Failed to load',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: TextStyle(fontSize: 12, color: AppColors.textMid),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
