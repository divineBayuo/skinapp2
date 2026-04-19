import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/id_badge.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

class PatientDetailScreen extends StatefulWidget {
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
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  late final TextEditingController _locationCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _sexCtrl;
  late final TextEditingController _emergNameCtrl;
  late final TextEditingController _emergContactCtrl;

  // Diagnosis fields (physician/researcher only)
  final _findingsCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  SkinNtdType _ntdType = SkinNtdType.unknown;
  DiagnosisStatus _status = DiagnosisStatus.suspected;
  bool _showDiagnosis = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _locationCtrl = TextEditingController(text: p.locationCoords);
    _dobCtrl = TextEditingController(text: p.formattedDob);
    _phoneCtrl = TextEditingController(text: p.phone);
    _sexCtrl = TextEditingController(text: p.sex);
    _emergNameCtrl = TextEditingController(text: p.emergencyName);
    _emergContactCtrl = TextEditingController(text: p.emergencyContact);

    if (p.diagnosis != null) {
      _ntdType = p.diagnosis!.ntdType;
      _status = p.diagnosis!.status;
      _findingsCtrl.text = p.diagnosis!.clinicalFindings;
      _treatmentCtrl.text = p.diagnosis!.treatmentPlan;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _locationCtrl,
      _dobCtrl,
      _phoneCtrl,
      _sexCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
      _findingsCtrl,
      _treatmentCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = widget.patient;
    final edit = widget.editMode && widget.role.canDiagnose;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        // Researcher sees timestamp in appBar
        actions: [
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient name
              Text(p.firstName, style: t.pageTitle),
              Text(p.lastName, style: t.pageTitle),

              const SizedBox(height: 12),

              // ID badge
              PatientIdBadge(idNumber: p.idNumber),

              const SizedBox(height: 24),

              // Location field (GPS coords)
              LabeledPillField(
                label: 'Location',
                field: PillField(
                  controller: _locationCtrl,
                  readOnly: !edit,
                  hint: 'GPS coordinates',
                ),
              ),
              const SizedBox(height: 14),

              // Date of Birth
              LabeledPillField(
                label: 'Date of Birth',
                field: PillField(
                  controller: _dobCtrl,
                  readOnly: !edit,
                  suffixIcon: edit
                      ? const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.textMid,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),

              // Phone + sex
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: LabeledPillField(
                      label: 'Phone',
                      field: PillField(
                        controller: _phoneCtrl,
                        readOnly: !edit,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: LabeledPillField(
                      label: 'Sex',
                      field: PillField(controller: _sexCtrl, readOnly: !edit),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              LabeledPillField(
                label: 'Emergency Name',
                field: PillField(controller: _emergNameCtrl, readOnly: !edit),
              ),
              const SizedBox(height: 14),

              LabeledPillField(
                label: 'Emergency Contact',
                field: PillField(
                  controller: _emergContactCtrl,
                  readOnly: !edit,
                  keyboardType: TextInputType.phone,
                ),
              ),

              // -- Diagnosis section (physician/researcher)----
              if (widget.role.canDiagnose) ...[
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: () => setState(() => _showDiagnosis = !_showDiagnosis),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Diagnosis',
                          style: TextStyle(
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
                if (_showDiagnosis) ...[
                  const SizedBox(height: 14),
                  // NTD type selector
                  Text('NTD Type', style: t.labelMedium),
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
                        items: SkinNtdType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          );
                        }).toList(),
                        onChanged: edit
                            ? (v) => setState(
                                () => _ntdType = v ?? SkinNtdType.unknown,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // status
                  Text('Status', style: t.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DiagnosisStatus.values.map((s) {
                      final sel = s == _status;
                      return GestureDetector(
                        onTap: edit ? () => setState(() => _status = s) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.navy : AppColors.fieldBg,
                            borderRadius: BorderRadius.circular(40),
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
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  LabeledPillField(
                    label: 'Clinical Findings',
                    field: PillField(
                      controller: _findingsCtrl,
                      readOnly: !edit,
                      maxLines: 3,
                      hint: 'Describe findings...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  LabeledPillField(
                    label: 'Treatment Plan',
                    field: PillField(
                      controller: _treatmentCtrl,
                      readOnly: !edit,
                      maxLines: 3,
                      hint: 'Recommended treatment...',
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 32),

              // Actions buttons row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // View/Collapse button (circular dark)
                  CircularActionButton(
                    icon: _showDiagnosis
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.check_rounded,
                    onTap: () =>
                        setState(() => _showDiagnosis = !_showDiagnosis),
                    size: 56,
                  ),
                  if (edit) ...[
                    const SizedBox(width: 16),
                    // Edit buttons
                    if (!widget.role.canExport)
                      CircularActionButton(
                        icon: Icons.edit_rounded,
                        onTap: () {},
                        size: 56,
                      ),
                    // Save button
                    const SizedBox(width: 16),
                    CircularActionButton(
                      icon: _saving
                          ? Icons.hourglass_empty_rounded
                          : Icons.save_alt_rounded,
                      onTap: _saving ? () {} : _save,
                      bgColor: widget.role.canExport
                          ? AppColors.saveRed
                          : AppColors.navy,
                      size: 56,
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
