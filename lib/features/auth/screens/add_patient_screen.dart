// -------------------------------------------------------
// ADD PATIENT SCREEN
// -------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

class AddPatientScreen extends StatefulWidget {
  final AccessRole role;
  const AddPatientScreen({super.key, required this.role});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _fullNameCtrl = TextEditingController();
  final _idCtrl = TextEditingController(text: 'Tap to generate');
  final _locationCtrl = TextEditingController(text: 'Tap to generate');
  final _dobCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _sexCtrl = TextEditingController();
  final _emergNameCtrl = TextEditingController();
  final _emergContactCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Progress: 0.0 -> 1.0 as fields are filled
  double _progress = 0.0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _fullNameCtrl,
      _phoneCtrl,
      _sexCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
    ]) {
      c.addListener(_updateProgress);
    }
    ;
  }

  void _updateProgress() {
    final filled = [
      _fullNameCtrl,
      _dobCtrl,
      _phoneCtrl,
      _sexCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
    ].where((c) => c.text.isNotEmpty).length;
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
      _sexCtrl,
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
        'GHA-${(now.millisecondsSinceEpoch % 900 + 100).toString()}'
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
      setState(() {
        _dobCtrl.text =
            '${picked.day.toString().padLeft(2, '0')}-'
            '${months[picked.month - 1]}-${picked.year}';
        _updateProgress();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _submitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patient record submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      // Reset form
      for (final c in [
        _fullNameCtrl,
        _phoneCtrl,
        _sexCtrl,
        _emergNameCtrl,
        _emergContactCtrl,
        _dobCtrl,
      ]) {
        c.clear();
      }
      _idCtrl.text = 'Tap to generate';
      _locationCtrl.text = 'Tap to generate';
      setState(() => _progress = 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text('Add New\nPatient', style: t.pageTitle),

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
                      Icons.auto_awesome_rounded,
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
                    child: PillField(
                      controller: _sexCtrl,
                      hint: 'Sex',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
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
