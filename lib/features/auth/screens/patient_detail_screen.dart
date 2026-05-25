// lib/features/auth/screens/patient_detail_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/auth_provider.dart';
import 'package:skinapp2/features/auth/providers/patient_provider.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/id_badge.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

// ── Section header — pure StatelessWidget, no logic inside ───────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.tealDeep),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: t.labelSmall?.copyWith(
              letterSpacing: 1.4,
              color: AppColors.tealDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: AppColors.tealDeep.withOpacity(0.25),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Read-only info row ────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool fullWidth; // FIX: now a proper constructor param
  const _InfoRow({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w600,
            color: AppColors.textMid,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            value.isEmpty ? '—' : value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textNavy,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Chip display (read-only) ──────────────────────────────────────────────────
class _ChipDisplay extends StatelessWidget {
  final List<String> items;
  const _ChipDisplay({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        '—',
        style: TextStyle(fontSize: 13, color: AppColors.textMid),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Online/offline badge ──────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool online;
  const _StatusBadge({required this.online});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 13,
            color: online ? AppColors.success : Colors.orange.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            online ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              color: online ? AppColors.success : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PatientDetailScreen extends ConsumerStatefulWidget {
  final PatientRecord patient;
  final AccessRole role;
  final bool editMode;

  const PatientDetailScreen({
    super.key,
    required this.patient,
    required this.role,
    required this.editMode,
  });

  @override
  ConsumerState<PatientDetailScreen> createState() =>
      _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  late Map<String, dynamic> _clinical;

  final _findingsCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _physicianName = TextEditingController();
  SkinNtdType _ntdType = SkinNtdType.unknown;
  DiagnosisStatus _status = DiagnosisStatus.suspected;
  bool _showDiagnosis = false;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _clinical = _parseClinical(widget.patient.clinicalNotes);
    final d = widget.patient.diagnosis;
    if (d != null) {
      _physicianName.text = d.physicianName;
      _ntdType = d.ntdType;
      _status = d.status;
      _findingsCtrl.text = d.clinicalFindings;
      _treatmentCtrl.text = d.treatmentPlan;
      _showDiagnosis = true;
    }
  }

  @override
  void dispose() {
    for (final c in [_findingsCtrl, _treatmentCtrl, _physicianName]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Map<String, dynamic> _parseClinical(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  List<String> _listField(String key) {
    final v = _clinical[key];
    if (v is List) return v.cast<String>();
    return [];
  }

  String _strField(String key) => _clinical[key]?.toString() ?? '';

  // ── Save diagnosis ────────────────────────────────────────────────────────────
  Future<void> _saveDiagnosis() async {
    if (_findingsCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinical findings.')),
      );
      return;
    }
    setState(() => _saving = true);

    final authState = ref.read(authProvider);
    final physicianId = authState.user?.id ?? '';

    final diagnosis = Diagnosis(
      physicianId: physicianId,
      physicianName: _physicianName.text.trim(),
      ntdType: _ntdType,
      status: _status,
      clinicalFindings: _findingsCtrl.text.trim(),
      treatmentPlan: _treatmentCtrl.text.trim(),
      diagnosedAt: DateTime.now(),
    );

    final success = await ref
        .read(patientProvider(widget.role).notifier)
        .addDiagnosis(widget.patient.id, diagnosis);

    if (mounted) {
      setState(() => _saving = false);
      final online = ref.read(patientProvider(widget.role)).online;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? online
                      ? 'Diagnosis saved and uploaded.'
                      : 'Diagnosis saved offline — will sync when reconnected.'
                : 'Failed to save diagnosis.',
          ),
          backgroundColor: success ? AppColors.success : Colors.redAccent,
        ),
      );
      if (success) Navigator.of(context).pop();
    }
  }

  // ── Export THIS patient as PDF + CSV ──────────────────────────────────────────
  // FIX: export operates on widget.patient only — no tab/filter references
  Future<void> _exportThisRecord() async {
    setState(() => _exporting = true);
    try {
      final p = widget.patient;
      final pdfFile = await _buildPdf(p);
      final csvFile = await _buildCsv(p);
      await Share.shareXFiles([
        XFile(pdfFile.path),
        XFile(csvFile.path),
      ], text: 'Patient Record — ${p.fullName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<File> _buildPdf(PatientRecord r) async {
    final pdf = pw.Document();
    final clinical = _parseClinical(r.clinicalNotes);

    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(
            'Patient Record',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 14),

          // Identity
          pw.Text(
            'PATIENT IDENTITY',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1A7A6E),
            ),
          ),
          pw.SizedBox(height: 6),
          _pdfRow('ID', r.idNumber),
          _pdfRow('Full Name', r.fullName),
          _pdfRow('Date of Birth', '${r.formattedDob} (${r.ageInYears} yrs)'),
          _pdfRow('Sex', r.sex),
          _pdfRow('Phone', r.phone),
          _pdfRow('Emergency Name', r.emergencyName),
          _pdfRow('Emergency Contact', r.emergencyContact),
          _pdfRow('Location (GPS)', r.locationCoords),
          _pdfRow('Facility', r.facilityName),
          _pdfRow('Collected At', r.formattedTimestamp),
          pw.SizedBox(height: 14),

          // Detection
          pw.Text(
            'DETECTION & CLASSIFICATION',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1A7A6E),
            ),
          ),
          pw.SizedBox(height: 6),
          _pdfRow(
            'Mode of Detection',
            clinical['modeOfDetection']?.toString() ?? '',
          ),
          _pdfRow(
            'Classification',
            clinical['classification']?.toString() ?? '',
          ),
          pw.SizedBox(height: 14),

          // Clinical
          pw.Text(
            'CLINICAL DETAILS',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF1A7A6E),
            ),
          ),
          pw.SizedBox(height: 6),
          _pdfRow(
            'Duration of Sickness',
            clinical['durationOfSickness']?.toString() ?? '',
          ),
          _pdfRow(
            'Examination Date',
            clinical['dateOfExamination']?.toString() ?? '',
          ),
          _pdfRow(
            'Limitation of Movement',
            clinical['limitationOfMovement']?.toString() ?? '',
          ),
          _pdfRow(
            'Number of Lesions',
            clinical['numberOfLesions']?.toString() ?? '',
          ),
          _pdfRow(
            'Biggest Lesion (cm)',
            clinical['diameterBiggestLesion']?.toString() ?? '',
          ),
          _pdfRow(
            'Lesion Types',
            (clinical['lesionTypes'] as List? ?? []).join(', '),
          ),
          _pdfRow(
            'Lesion Locations',
            (clinical['lesionLocations'] as List? ?? []).join(', '),
          ),
          _pdfRow(
            'Clinical Suspicion',
            (clinical['clinicalSuspicion'] as List? ?? []).join(', '),
          ),
          pw.SizedBox(height: 6),
          if ((clinical['additionalNotes'] ?? '').toString().isNotEmpty) ...[
            pw.Text(
              'Additional Notes:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(clinical['additionalNotes'].toString()),
          ],

          // Diagnosis
          if (r.diagnosis != null) ...[
            pw.SizedBox(height: 14),
            pw.Text(
              'DIAGNOSIS',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFF1A7A6E),
              ),
            ),
            pw.SizedBox(height: 6),
            _pdfRow('NTD Type', r.diagnosis!.ntdType.label),
            _pdfRow('Status', r.diagnosis!.status.label),
            _pdfRow('Physician', r.diagnosis!.physicianName),
            _pdfRow('Findings', r.diagnosis!.clinicalFindings),
            _pdfRow('Treatment Plan', r.diagnosis!.treatmentPlan),
            _pdfRow('Diagnosed At', r.diagnosis!.diagnosedAt.toIso8601String()),
          ],
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${r.idNumber}_record.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 160,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value.isEmpty ? '—' : value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Future<File> _buildCsv(PatientRecord r) async {
    final clinical = _parseClinical(r.clinicalNotes);
    final rows = [
      ['Field', 'Value'],
      ['ID', r.idNumber],
      ['Full Name', r.fullName],
      ['Date of Birth', '${r.formattedDob} (${r.ageInYears} yrs)'],
      ['Sex', r.sex],
      ['Phone', r.phone],
      ['Emergency Name', r.emergencyName],
      ['Emergency Contact', r.emergencyContact],
      ['Location (GPS)', r.locationCoords],
      ['Facility', r.facilityName],
      ['Collected At', r.formattedTimestamp],
      ['Mode of Detection', clinical['modeOfDetection']?.toString() ?? ''],
      ['Classification', clinical['classification']?.toString() ?? ''],
      [
        'Duration of Sickness',
        clinical['durationOfSickness']?.toString() ?? '',
      ],
      ['Examination Date', clinical['dateOfExamination']?.toString() ?? ''],
      [
        'Limitation of Movement',
        clinical['limitationOfMovement']?.toString() ?? '',
      ],
      ['Number of Lesions', clinical['numberOfLesions']?.toString() ?? ''],
      [
        'Biggest Lesion (cm)',
        clinical['diameterBiggestLesion']?.toString() ?? '',
      ],
      ['Lesion Types', (clinical['lesionTypes'] as List? ?? []).join('; ')],
      [
        'Lesion Locations',
        (clinical['lesionLocations'] as List? ?? []).join('; '),
      ],
      [
        'Clinical Suspicion',
        (clinical['clinicalSuspicion'] as List? ?? []).join('; '),
      ],
      ['Additional Notes', clinical['additionalNotes']?.toString() ?? ''],
      ['Diagnosed', r.hasDiagnosis ? 'Yes' : 'No'],
      if (r.diagnosis != null) ...[
        ['NTD Type', r.diagnosis!.ntdType.label],
        ['Status', r.diagnosis!.status.label],
        ['Physician', r.diagnosis!.physicianName],
        ['Findings', r.diagnosis!.clinicalFindings],
        ['Treatment Plan', r.diagnosis!.treatmentPlan],
        ['Diagnosed At', r.diagnosis!.diagnosedAt.toIso8601String()],
      ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${r.idNumber}_record.csv');
    await file.writeAsString(csv);
    return file;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = widget.patient;
    final canEdit = widget.editMode && widget.role.canDiagnose;
    final online = ref.watch(patientProvider(widget.role)).online;

    final modeOfDetection = _strField('modeOfDetection');
    final modeOther = _strField('modeOfDetectionOther');
    final classification = _strField('classification');
    final duration = _strField('durationOfSickness');
    final examDate = _strField('dateOfExamination');
    final limitation = _strField('limitationOfMovement');
    final numLesions = _strField('numberOfLesions');
    final lesionDiam = _strField('diameterBiggestLesion');
    final lesionTypes = _listField('lesionTypes');
    final lesionLocations = _listField('lesionLocations');
    final clinicalSuspicion = _listField('clinicalSuspicion');
    final suspicionOther = _strField('clinicalSuspicionOther');
    final additionalNotes = _strField('additionalNotes');
    final localPhotoPaths = _listField('localPhotoPaths');
    final cloudPhotoUrls = p.photoUrls;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.bgLight,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        actions: [
          _StatusBadge(online: online),
          const SizedBox(width: 8),
          if (widget.role.canViewTimestamps)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roleResearcher.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.formattedTimestamp,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roleResearcher,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + ID
              Text(p.firstName, style: t.pageTitle),
              if (p.lastName.isNotEmpty) Text(p.lastName, style: t.pageTitle),
              const SizedBox(height: 12),
              PatientIdBadge(idNumber: p.idNumber),

              // Diagnosed chip
              if (p.hasDiagnosis) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Diagnosed · ${p.diagnosis!.ntdType.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Section A ─────────────────────────────────────────────────
              const _SectionHeader(
                title: 'Patient Identity',
                icon: Icons.person_outline_rounded,
              ),
              _InfoRow(label: 'Full Name', value: p.fullName, fullWidth: true),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Date of Birth',
                value: '${p.formattedDob}  (${p.ageInYears} yrs)',
                fullWidth: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _InfoRow(label: 'Phone', value: p.phone),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(label: 'Sex', value: p.sex),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      label: 'Emergency Name',
                      value: p.emergencyName,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(
                      label: 'Emergency Contact',
                      value: p.emergencyContact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Location (GPS)',
                value: p.locationCoords,
                fullWidth: true,
              ),
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Facility',
                value: p.facilityName,
                fullWidth: true,
              ),

              // ── Section B ─────────────────────────────────────────────────
              if (modeOfDetection.isNotEmpty || classification.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Detection & Classification',
                  icon: Icons.track_changes_rounded,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        label: 'Mode of Detection',
                        value:
                            modeOfDetection == 'Other' && modeOther.isNotEmpty
                            ? 'Other: $modeOther'
                            : modeOfDetection,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoRow(
                        label: 'Classification',
                        value: classification,
                      ),
                    ),
                  ],
                ),
              ],

              // ── Section C ─────────────────────────────────────────────────
              const _SectionHeader(
                title: 'Clinical Details',
                icon: Icons.medical_information_outlined,
              ),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      label: 'Duration of Sickness',
                      value: duration,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(label: 'Examination Date', value: examDate),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoRow(
                      label: 'Limitation of Movement',
                      value: limitation,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(label: 'No. of Lesions', value: numLesions),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoRow(
                      label: 'Biggest Lesion (cm)',
                      value: lesionDiam,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (lesionTypes.isNotEmpty) ...[
                Text(
                  'TYPE OF LESION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                _ChipDisplay(items: lesionTypes),
                const SizedBox(height: 16),
              ],

              if (lesionLocations.isNotEmpty) ...[
                Text(
                  'LOCATION OF LESION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                _ChipDisplay(items: lesionLocations),
                const SizedBox(height: 16),
              ],

              if (clinicalSuspicion.isNotEmpty) ...[
                Text(
                  'CLINICAL SUSPICION',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                _ChipDisplay(
                  items: clinicalSuspicion
                      .map(
                        (s) => s == 'Other' && suspicionOther.isNotEmpty
                            ? 'Other: $suspicionOther'
                            : s,
                      )
                      .toList(),
                ),
              ],

              // ── Section D — Photos ─────────────────────────────────────────
              if (localPhotoPaths.isNotEmpty || cloudPhotoUrls.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Lesion Photos',
                  icon: Icons.camera_alt_outlined,
                ),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...cloudPhotoUrls.map((url) => _PhotoThumb.network(url)),
                      ...localPhotoPaths
                          .where((path) => File(path).existsSync())
                          .map((path) => _PhotoThumb.file(path)),
                    ],
                  ),
                ),
              ],

              // ── Section E — Notes ──────────────────────────────────────────
              if (additionalNotes.isNotEmpty) ...[
                const _SectionHeader(
                  title: 'Additional Notes',
                  icon: Icons.notes_rounded,
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    additionalNotes,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppColors.textNavy,
                    ),
                  ),
                ),
              ],

              // ── Section F — Diagnosis ──────────────────────────────────────
              if (widget.role.canDiagnose) ...[
                const SizedBox(height: 28),
                Material(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(40),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () =>
                        setState(() => _showDiagnosis = !_showDiagnosis),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p.hasDiagnosis ? 'Edit Diagnosis' : 'Add Diagnosis',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Icon(
                            _showDiagnosis
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.teal,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_showDiagnosis) ...[
                  const SizedBox(height: 16),
                  Text(
                    'NTD Type',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBg,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SkinNtdType>(
                        value: _ntdType,
                        isExpanded: true,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textNavy,
                        ),
                        items: SkinNtdType.values
                            .map(
                              (nt) => DropdownMenuItem(
                                value: nt,
                                child: Text(nt.label),
                              ),
                            )
                            .toList(),
                        onChanged: canEdit
                            ? (v) => setState(
                                () => _ntdType = v ?? SkinNtdType.unknown,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Status',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DiagnosisStatus.values.map((s) {
                      final sel = s == _status;
                      return Material(
                        color: sel ? AppColors.navy : AppColors.fieldBg,
                        borderRadius: BorderRadius.circular(40),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: canEdit
                              ? () => setState(() => _status = s)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text(
                              s.label,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.textMid,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Physician Name',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabeledPillField(
                    label: '',
                    field: PillField(
                      controller: _physicianName,
                      readOnly: !canEdit,
                      hint: 'Physician full name',
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Clinical Findings',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabeledPillField(
                    label: '',
                    field: PillField(
                      controller: _findingsCtrl,
                      readOnly: !canEdit,
                      maxLines: 4,
                      hint: 'Describe your clinical findings…',
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Treatment Plan',
                    style: t.labelMedium?.copyWith(
                      color: AppColors.textMid,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LabeledPillField(
                    label: '',
                    field: PillField(
                      controller: _treatmentCtrl,
                      readOnly: !canEdit,
                      maxLines: 4,
                      hint: 'Recommended treatment…',
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 36),

              // ── Action buttons ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back
                  CircularActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                    size: 52,
                    bgColor: AppColors.fieldBg,
                    iconColor: AppColors.navy,
                  ),

                  // Save diagnosis — physician only, when panel is open
                  if (canEdit && _showDiagnosis) ...[
                    const SizedBox(width: 16),
                    CircularActionButton(
                      icon: _saving
                          ? Icons.hourglass_empty_rounded
                          : Icons.save_alt_rounded,
                      onTap: _saving ? () {} : _saveDiagnosis,
                      bgColor: AppColors.saveRed,
                      size: 62,
                    ),
                  ],

                  // Export — researchers and physicians
                  // FIX: was checking !canExport && !canDiagnose (nobody)
                  // Now: anyone with canExport OR canDiagnose can export
                  if (widget.role.canExport || widget.role.canDiagnose) ...[
                    const SizedBox(width: 16),
                    CircularActionButton(
                      icon: _exporting
                          ? Icons.hourglass_empty_rounded
                          : Icons.ios_share_rounded,
                      onTap: _exporting ? () {} : _exportThisRecord,
                      bgColor: AppColors.navy,
                      size: 52,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Photo thumbnail ───────────────────────────────────────────────────────────
class _PhotoThumb extends StatelessWidget {
  final String? networkUrl;
  final String? localPath;
  const _PhotoThumb._({this.networkUrl, this.localPath});

  factory _PhotoThumb.network(String url) => _PhotoThumb._(networkUrl: url);
  factory _PhotoThumb.file(String path) => _PhotoThumb._(localPath: path);

  @override
  Widget build(BuildContext context) {
    final isNet = networkUrl != null;
    return GestureDetector(
      onTap: () => _showFull(context),
      child: Container(
        width: 110,
        height: 110,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isNet
              ? Image.network(
                  networkUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          color: AppColors.fieldBg,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => _ph(Icons.broken_image_rounded),
                )
              : Image.file(
                  File(localPath!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _ph(Icons.image_not_supported_rounded),
                ),
        ),
      ),
    );
  }

  Widget _ph(IconData icon) => Container(
    color: AppColors.fieldBg,
    child: Center(child: Icon(icon, color: AppColors.textMid, size: 28)),
  );

  void _showFull(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: networkUrl != null
                  ? Image.network(networkUrl!, fit: BoxFit.contain)
                  : Image.file(File(localPath!), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
