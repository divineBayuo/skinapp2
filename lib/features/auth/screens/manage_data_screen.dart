// lib/features/auth/screens/manage_data_screen.dart
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/patient_provider.dart';
import 'package:skinapp2/features/auth/screens/patient_detail_screen.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/empty_state.dart';
import 'package:skinapp2/shared/widgets/patient_list_row.dart';
import 'package:skinapp2/shared/widgets/search_date_filter_row.dart';

class ManageDataScreen extends ConsumerStatefulWidget {
  final AccessRole role;
  const ManageDataScreen({super.key, required this.role});

  @override
  ConsumerState<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends ConsumerState<ManageDataScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedDateLabel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Tabs only shown to roles that can distinguish pending/diagnosed
    _tabController = TabController(
      length: widget.role.canDiagnose ? 3 : 2,
      vsync: this,
    );
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Filter logic ─────────────────────────────────────────────────────────────
  List<PatientRecord> _applyFilters(List<PatientRecord> source) {
    var list = source;
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (p) =>
                p.fullName.toLowerCase().contains(q) ||
                p.idNumber.toLowerCase().contains(q) ||
                p.locationCoords.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_selectedDate != null) {
      list = list
          .where(
            (p) =>
                p.collectedAt.year == _selectedDate!.year &&
                p.collectedAt.month == _selectedDate!.month &&
                p.collectedAt.day == _selectedDate!.day,
          )
          .toList();
    }
    return list;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      const months = [
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
      setState(() {
        _selectedDate = picked;
        _selectedDateLabel =
            '${picked.day}-${months[picked.month - 1]}-${picked.year}';
      });
    }
  }

  void _clearDate() => setState(() {
    _selectedDate = null;
    _selectedDateLabel = null;
  });

  // pdf generator function
  Future<File> _generatePdf(List<PatientRecord> records) async {
    final pdf = pw.Document();

    for (final r in records) {
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Patient Record',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              pw.Text('ID: ${r.idNumber}'),
              pw.Text('Name: ${r.fullName}'),
              pw.Text('Sex: ${r.sex}'),
              pw.Text('DOB: ${r.formattedDob}'),
              pw.Text('Phone: ${r.phone}'),
              pw.Text('Emergency: ${r.emergencyName} / ${r.emergencyContact}'),
              pw.Text('Location: ${r.locationCoords}'),
              pw.Text('Community: ${r.community}'),
              pw.Text('Facility: ${r.facilityName}'),
              pw.Text('Samples Collected:, ${r.formattedSamplesCollectedAt}'),
              pw.Text('Samples Received: ${r.formattedSamplesReceivedAt}'),
              pw.Text('Collected: ${r.formattedTimestamp}'),

              pw.SizedBox(height: 10),
              pw.Text(
                'Clinical Notes:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(r.clinicalNotes),
              if (r.diagnosis != null) ...[
                pw.SizedBox(height: 10),
                pw.Text(
                  'Diagnosis:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text('NTD Type: ${r.diagnosis!.ntdType.label}'),
                pw.Text('Status: ${r.diagnosis!.status.label}'),
                pw.Text('Findings: ${r.diagnosis!.clinicalFindings}'),
                pw.Text('Treatment: ${r.diagnosis!.treatmentPlan}'),
              ],
            ],
          ),
        ),
      );
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/patients_record.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // csv generator
  Future<File> _generateCsv(List<PatientRecord> records) async {
    final rows = <List<dynamic>>[
      // Header row
      [
        'ID',
        'Name',
        'Sex',
        'DOB',
        'Phone',
        'Emergency Name',
        'Emergency Contact',
        'Location',
        'Community',
        'Facility',
        'Collected At',
        'Samples Collected',
        'Samples Received',
        'Diagnosis',
        'NTD Type',
        'Status',
        'Findings',
        'Treatment',
      ],
      // Data rows
      ...records.map(
        (r) => [
          r.idNumber,
          r.fullName,
          r.sex,
          r.formattedDob,
          r.phone,
          r.emergencyName,
          r.emergencyContact,
          r.locationCoords,
          r.community,
          r.facilityName,
          r.formattedTimestamp,
          r.formattedSamplesCollectedAt,
          r.formattedSamplesReceivedAt,
          r.hasDiagnosis ? 'Yes' : 'No',
          r.diagnosis?.ntdType.label ?? '',
          r.diagnosis?.status.label ?? '',
          r.diagnosis?.clinicalFindings ?? '',
          r.diagnosis?.treatmentPlan ?? '',
        ],
      ),
    ];

    final csvData = const ListToCsvConverter().convert(rows);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/patients_export.csv');
    await file.writeAsString(csvData);

    return file;
  }

  // ── Export ─────────────────────────────────────────────────────────────
  Future<void> _onExport(List<PatientRecord> records) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No records to export.')));
      return;
    }

    try {
      // generate files
      final pdfFile = await _generatePdf(records);
      final csvFile = await _generateCsv(records);

      //share both
      await Share.shareXFiles([
        XFile(pdfFile.path),
        XFile(csvFile.path),
      ], text: 'Patient Record Export - ${records.length} record(s)');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  // ── Manual sync ─────────────────────────────────────────────────────────────
  Future<void> _onSync() async {
    await ref.read(patientProvider(widget.role).notifier).syncNow();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sync complete.')));
    }
  }

  // ── Patient list view ────────────────────────────────────────────────────────
  Widget _buildList(List<PatientRecord> records) {
    final filtered = _applyFilters(records);
    if (filtered.isEmpty) {
      return const EmptyState(
        title: 'No records found',
        subtitle: 'Try adjusting your search or date filter.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) => PatientListRow(
        patient: filtered[i],
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PatientDetailScreen(
              patient: filtered[i],
              role: widget.role,
              editMode: widget.role.canDiagnose,
            ),
          ),
        ),
        showTimestamp: widget.role.canViewTimestamps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(patientProvider(widget.role));
    final online = state.online;
    final unsyncedCount = state.unsyncedCount;

    final allRecords = state.records;
    final pending = allRecords.where((p) => !p.hasDiagnosis).toList();
    final diagnosed = allRecords.where((p) => p.hasDiagnosis).toList();

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text('Manage\nPatient\nData', style: t.pageTitle),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Offline / online badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: online
                                    ? AppColors.success.withOpacity(0.12)
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    online
                                        ? Icons.cloud_done_rounded
                                        : Icons.cloud_off_rounded,
                                    size: 13,
                                    color: online
                                        ? AppColors.success
                                        : Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    online ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: online
                                          ? AppColors.success
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Sync button
                            if (online)
                              CircularActionButton(
                                icon: Icons.sync_rounded,
                                onTap: _onSync,
                                size: 42,
                              ),
                            const SizedBox(width: 8),
                            // Export button (role-gated)
                            if (widget.role.canExport)
                              CircularActionButton(
                                icon: Icons.save_alt_rounded,
                                onTap: () {
                                  final currentRecords = _applyFilters(
                                    _tabController.index == 0
                                        ? allRecords
                                        : _tabController.index == 1
                                        ? pending
                                        : diagnosed,
                                  );
                                  _onExport(currentRecords);
                                },
                                bgColor: AppColors.saveRed,
                                size: 42,
                              ),
                          ],
                        ),
                        // Unsynced badge — only shown to collectors
                        if (widget.role.isCollector && unsyncedCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Text(
                              '$unsyncedCount pending sync',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Physician/Researcher notice
                if (!widget.role.isCollector) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Showing synced records only. '
                            'Offline-only records are visible to the collector '
                            'once they connect and upload.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Search + date filter
                SearchDateRow(
                  searchCtrl: _searchCtrl,
                  onDateTap: _pickDate,
                  selectedDate: _selectedDateLabel,
                ),

                // Active date chip with clear button
                if (_selectedDateLabel != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _clearDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedDateLabel!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: AppColors.navy,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  labelColor: AppColors.navy,
                  unselectedLabelColor: AppColors.textMid,
                  indicatorColor: AppColors.tealDeep,
                  indicatorWeight: 2,
                  tabs: [
                    Tab(text: 'All (${allRecords.length})'),
                    Tab(text: 'Pending (${pending.length})'),
                    if (widget.role.canDiagnose)
                      Tab(text: 'Diagnosed (${diagnosed.length})'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab views ────────────────────────────────────────────────────────
          Expanded(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildList(allRecords),
                      _buildList(pending),
                      if (widget.role.canDiagnose) _buildList(diagnosed),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
