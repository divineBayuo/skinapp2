// -------------------------------------------------------
// ADD PATIENT SCREEN
// -------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/patient_provider.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

class AddPatientScreen extends ConsumerStatefulWidget {
  final AccessRole role;
  const AddPatientScreen({super.key, required this.role});

  @override
  ConsumerState<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends ConsumerState<AddPatientScreen> {
  final _fullNameCtrl = TextEditingController();
  final _idCtrl = TextEditingController(text: 'Tap to generate');
  final _locationCtrl = TextEditingController(text: 'Tap to generate');
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergContactCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedSex;
  static const _sexOptions = ['Male', 'Female'];

  // Progress: 0.0 -> 1.0 as fields are filled
  double _progress = 0.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _fullNameCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
    ]) {
      c.addListener(_updateProgress);
    }
  }

  void _updateProgress() {
    int filled = [
      _fullNameCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
    ].where((c) => c.text.isNotEmpty).length;
    if (_dobCtrl.text.isNotEmpty) filled++;
    if (_selectedSex != null) filled++;
    setState(() => _progress = filled / 6);
  }

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl,
      _idCtrl,
      _locationCtrl,
      _dobCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _generateId() {
    final now = DateTime.now();
    final id =
        'GHA-${(now.millisecondsSinceEpoch % 900 + 100)}'
        '-${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year.toString().substring(2)}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    setState(() => _idCtrl.text = id);
  }

  void _generateLocation() {
    // In production: use geolocator
    setState(() => _locationCtrl.text = '5.6037168, -0.6914456');
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
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
      final months = [
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
      _dobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}-'
          '${months[picked.month - 1]}-${picked.year}';
      _updateProgress();
    }
  }

  String _generateUniqueId() {
    final now = DateTime.now();
    return 'GHA-${(now.millisecondsSinceEpoch % 900 + 100)}'
        '-${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year.toString().substring(2)}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSex == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select sex.')));
      return;
    }

    setState(() => _submitting = true);

    // Parse DOB
    final parts = _dobCtrl.text.split('-');
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
    final dob = DateTime(
      int.parse(parts[2]),
      months.indexOf(parts[1]) + 1,
      int.parse(parts[0]),
    );

    final now = DateTime.now();
    final idNo = _idCtrl.text == 'Tap to generate'
        ? _generateUniqueId()
        : _idCtrl.text;
    final loc = _locationCtrl.text == 'Tap to generate'
        ? ''
        : _locationCtrl.text;

    final record = PatientRecord(
      id: idNo,
      idNumber: idNo,
      locationCoords: loc,
      fullName: _fullNameCtrl.text.trim(),
      dateOfBirth: dob,
      phone: _phoneCtrl.text.trim(),
      sex: _selectedSex!,
      emergencyName: _emergNameCtrl.text.trim(),
      emergencyContact: _emergContactCtrl.text.trim(),
      photoUrls: const [],
      clinicalNotes: '',
      collectorId: 'current_user_id',
      facilityName: 'Main Facility',
      collectedAt: now,
      updatedAt: now,
    );

    // save via provider (handles offline + online)
    final success = await ref.read(patientProvider.notifier).addRecord(record);

    if (mounted) {
      setState(() => _submitting = false);
      final online = ref.read(isOnlineProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? online
                      ? 'Patient record saved and uploaded.'
                      : 'Saved offline - will sync when reconnected.'
                : 'Failed to save record.',
          ),
          backgroundColor: success ? AppColors.success : Colors.redAccent,
        ),
      );
      if (success) _resetForm();
    }
  }

  void _resetForm() {
    for (final c in [
      _fullNameCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
      _dobCtrl,
    ]) {
      c.clear();
    }
    _idCtrl.text = 'Tap to generate';
    _locationCtrl.text = 'Tap to generate';
    setState(() {
      _selectedSex = null;
      _progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final online = ref.watch(isOnlineProvider);

    return SafeArea(
      bottom: false,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Title
                  Expanded(child: Text('Add New\nPatient', style: t.pageTitle)),
                  // Offline badge indicator
                  if (!online)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 14,
                            color: Colors.orange.shade800,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 28),

              // Full Name
              PillField(
                controller: _fullNameCtrl,
                hint: 'Full Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 12),

              // Auto-generated id
              GestureDetector(
                onTap: _generateId,
                child: AbsorbPointer(
                  child: PillField(
                    controller: _idCtrl,
                    hint: 'ID No: Tap to generate',
                    suffixIcon: const Icon(
                      Icons.card_membership_rounded,
                      size: 16,
                      color: AppColors.tealDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Auto-generated location
              GestureDetector(
                onTap: _generateLocation,
                child: AbsorbPointer(
                  child: PillField(
                    controller: _locationCtrl,
                    hint: 'Location: Tap to generate',
                    suffixIcon: const Icon(
                      Icons.my_location_rounded,
                      size: 16,
                      color: AppColors.tealDeep,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date of Birth
              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: PillField(
                    controller: _dobCtrl,
                    hint: 'Date of Birth',
                    suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: AppColors.textMid,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Phone + Sex in a Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: PillField(
                      controller: _phoneCtrl,
                      hint: 'Phone',
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedSex,
                      decoration: InputDecoration(
                        hintText: 'Sex',
                        hintStyle: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.fieldBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.expand_more, size: 18),
                      items: _sexOptions
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() => _selectedSex = v);
                        _updateProgress();
                      },
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Emergency Name
              PillField(
                controller: _emergNameCtrl,
                hint: 'Emergency Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Emergency Contact
              PillField(
                controller: _emergContactCtrl,
                hint: 'Emergency Contact',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 28),

              // Submit circular button - dark navy circle with checkmark
              Center(
                child: CircularActionButton(
                  icon: _submitting
                      ? Icons.hourglass_empty_rounded
                      : Icons.check_rounded,
                  onTap: _submitting ? () {} : _submit,
                  size: 62,
                ),
              ),

              const SizedBox(height: 20),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppColors.fieldBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
