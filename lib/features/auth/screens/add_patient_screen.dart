// -------------------------------------------------------
// ADD PATIENT SCREEN
// -------------------------------------------------------

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/auth_provider.dart';
import 'package:skinapp2/features/auth/providers/patient_provider.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/services/location_service.dart';
import 'package:skinapp2/services/photo_service.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

// --- Helper section header ----------------------
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

// --- Helper pill-stylled chip selector (multi/single)
class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final bool multiSelect;
  final ValueChanged<String> onToggle;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onToggle,
    this.multiSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final active = selected.contains(opt);
        return GestureDetector(
          onTap: () => onToggle(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active ? AppColors.navy : AppColors.fieldBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: active ? AppColors.navy : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white : AppColors.textMid,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// --- Helper labelled pill dropdown -------------------
Widget _pillDropdown<T>({
  required T? value,
  required String hint,
  required List<T> items,
  required ValueChanged<T?> onChanged,
  String? Function(T?)? validator,
  String Function(T)? labelBuilder,
}) {
  return DropdownButtonFormField<T>(
    value: value,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMid, fontSize: 14),
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    items: items
        .map(
          (i) => DropdownMenuItem<T>(
            value: i,
            child: Text(
              labelBuilder != null ? labelBuilder(i) : i.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
        )
        .toList(),
    onChanged: onChanged,
    validator: validator,
  );
}

// ---------- SCREEN ----------------------------

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

  // section b
  String? _modeOfDetection;
  final _modeOtherControl = TextEditingController();
  String? _classification;

  static const _detectionModes = ['Active Screening', 'Passive', 'Other'];
  static const _classificationOptions = ['New', 'Recurrent/Relapse'];

  // section c
  final _durationCtrl = TextEditingController();
  final _examinationDateCtrl = TextEditingController();
  String? _limitationOfMovement;
  final _numLesionsCtrl = TextEditingController();
  final _maxLesionDiamCtrl = TextEditingController();

  static const _limitOptions = ['Yes', 'No'];

  // multi-select - type of lesion
  final Set<String> _lesionTypes = {};
  static const _lesionTypeOptions = [
    'Macule',
    'Oedema',
    'Papilloma',
    'Plaque',
    'Ulcer',
    'Nodule',
    'Osteomyelitis',
    'Papule',
    'Skin Patches',
    'Vesicles',
  ];

  // multi-select - location of lesion
  final Set<String> _lesionLocations = {};
  static const _lesionLocationOptions = [
    'Abdomen',
    'Breast',
    'Buttocks',
    'Toe',
    'Face',
    'Upper Limb',
    'Genitalia',
    'Back',
    'Thorax',
    'Eye',
    'Ear',
    'Lower Limb',
    'Finger',
    'Inguinal/Groin',
  ];

  // multi-select - clinical suspicion
  final Set<String> _clinicalSuspicion = {};
  final _suspicionOtherCtrl = TextEditingController();
  static const _suspicionOptions = [
    'BU',
    'CL',
    'Leprosy',
    'Lymphatic Filariasis',
    'Yaws',
    'Other',
  ];

  // section d
  final List<File> _lesionPhotos = [];
  final _notesCtrl = TextEditingController();

  // Progress: 0.0 -> 1.0 as fields are filled
  double _progress = 0.0;
  bool _submitting = false;
  static const int _totalFields = 15;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _fullNameCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
      _durationCtrl,
      _numLesionsCtrl,
      _maxLesionDiamCtrl,
      _modeOtherControl,
      _suspicionOtherCtrl,
    ]) {
      c.addListener(_updateProgress);
    }
  }

  void _updateProgress() {
    int filled = 0;

    // section a
    if (_fullNameCtrl.text.isNotEmpty) filled++;
    if (_dobCtrl.text.isNotEmpty) filled++;
    if (_phoneCtrl.text.isNotEmpty) filled++;
    if (_selectedSex != null) filled++;
    if (_emergContactCtrl.text.isNotEmpty) filled++;
    if (_emergNameCtrl.text.isNotEmpty) filled++;

    // section b
    if (_modeOfDetection != null) filled++;
    if (_classification != null) filled++;

    // section c
    if (_durationCtrl.text.isNotEmpty) filled++;
    if (_examinationDateCtrl.text.isNotEmpty) filled++;
    if (_limitationOfMovement != null) filled++;
    if (_numLesionsCtrl.text.isNotEmpty) filled++;
    if (_lesionTypes.isNotEmpty) filled++;
    if (_lesionLocations.isNotEmpty) filled++;
    if (_clinicalSuspicion.isNotEmpty) filled++;

    setState(() => _progress = filled / _totalFields);
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
      _durationCtrl,
      _examinationDateCtrl,
      _numLesionsCtrl,
      _maxLesionDiamCtrl,
      _modeOtherControl,
      _suspicionOtherCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // auto generation
  String _buildId() {
    final now = DateTime.now();
    return 'GHA-${(now.millisecondsSinceEpoch % 900 + 100)}'
        '-${now.day.toString().padLeft(2, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.year.toString().substring(2)}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  void _generateId() {
    setState(() => _idCtrl.text = _buildId());
  }

  bool _locating = false;

  Future<void> _generateLocation() async {
    // In production: use geolocator
    // setState(() => _locationCtrl.text = '5.6037168, -0.6914456');
    setState(() => _locating = true);
    final coords = await LocationService().getCurrentCoords();
    setState(() {
      _locating = false;
      if (coords != null) {
        _locationCtrl.text = coords;
      } else {
        // show a snackbar, avoid silent fail
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not get location. Check that location services are enabled.',
            ),
          ),
        );
      }
    });
  }

  // date pickers
  static const _months = [
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

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${_months[d.month - 1]}-${d.year}';

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      _dobCtrl.text = _fmtDate(picked);
      _updateProgress();
    }
  }

  Future<void> _pickExaminationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: _datePickerTheme,
    );
    if (picked != null) {
      setState(() => _examinationDateCtrl.text = _fmtDate(picked));
      _updateProgress();
    }
  }

  Widget Function(BuildContext, Widget?) get _datePickerTheme =>
      (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navy,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      );

  // photo picker
  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    // persist to doc dir immediately, not temp cache
    final permanentPath = await PhotoService().persistPhoto(picked.path);
    setState(() => _lesionPhotos.add(File(permanentPath)));

    /* final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() => _lesionPhotos.add(File(file.path)));
    } */
  }

  // --- Chip toggles -------------------
  void _toggleLesionType(String v) {
    setState(() {
      _lesionTypes.contains(v) ? _lesionTypes.remove(v) : _lesionTypes.add(v);
    });
    _updateProgress();
  }

  void _toggleLesionLocation(String v) {
    setState(() {
      _lesionLocations.contains(v)
          ? _lesionLocations.remove(v)
          : _lesionLocations.add(v);
    });
    _updateProgress();
  }

  void _toggleSuspicion(String v) {
    setState(() {
      _clinicalSuspicion.contains(v)
          ? _clinicalSuspicion.remove(v)
          : _clinicalSuspicion.add(v);
    });
    _updateProgress();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    // extra non-form-field validations
    if (_selectedSex == null ||
        _modeOfDetection == null ||
        _classification == null ||
        _limitationOfMovement == null ||
        _lesionTypes.isEmpty ||
        _lesionLocations.isEmpty ||
        _clinicalSuspicion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required selections.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // guard
    if (_dobCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date of birth.')),
      );
      return;
    }

    setState(() => _submitting = true);

    // replacing authProvider below with top-level
    final authState = ref.read(authProvider);
    final currentUser = authState.user;

    if (currentUser == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to add a patient.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Parse DOB
    final dobParts = _dobCtrl.text.split('-');
    final dob = DateTime(
      int.parse(dobParts[2]),
      _months.indexOf(dobParts[1]) + 1,
      int.parse(dobParts[0]),
    );

    final now = DateTime.now();
    final idNo = _idCtrl.text == 'Tap to generate' ? _buildId() : _idCtrl.text;

    // build extra clinical fields map to store in clinicalNotes as JSON
    // (until PatientRecord model is extended with dedicated fields)
    final clinicalData = {
      'modeOfDetection': _modeOfDetection,
      if (_modeOfDetection == 'Other')
        'modeOfDetectionOther': _modeOtherControl.text,
      'classification': _classification,
      'durationOfSickness': _durationCtrl.text,
      'dateOfExamination': _examinationDateCtrl.text,
      'limitationOfMovement': _limitationOfMovement,
      'numberOfLesions': _numLesionsCtrl.text,
      'diameterBiggestLesion': _maxLesionDiamCtrl.text,
      'lesionTypes': _lesionTypes.toList(),
      'lesionLocations': _lesionLocations.toList(),
      'clinicalSuspicion': _clinicalSuspicion.toList(),
      if (_clinicalSuspicion.contains('Other'))
        'clinicalSuspicionOther': _suspicionOtherCtrl.text,
      'additionalNotes': _notesCtrl.text,
      // Photo paths stored locally; upload URLs will be set after sync
      'localPhotoPaths': _lesionPhotos.map((f) => f.path).toList(),
    };

    // Temporarily add this in _submit(), right after building clinicalData:
    debugPrint('📸 Photos at submit time: ${_lesionPhotos.length}');
    debugPrint('📸 Paths: ${_lesionPhotos.map((f) => f.path).toList()}');
    debugPrint(
      '📸 clinicalData localPhotoPaths: ${clinicalData['localPhotoPaths']}',
    );

    final record = PatientRecord(
      id: idNo,
      idNumber: idNo,
      locationCoords: _locationCtrl.text == 'Tap to generate'
          ? ''
          : _locationCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      dateOfBirth: dob,
      phone: _phoneCtrl.text.trim(),
      sex: _selectedSex!,
      emergencyName: _emergNameCtrl.text.trim(),
      emergencyContact: _emergContactCtrl.text.trim(),
      photoUrls: const [], // populated after cloud upload on sync
      clinicalNotes: jsonEncode(clinicalData), // serialize as JSON
      collectorId: currentUser.id,
      facilityName: currentUser.facilityName ?? 'Unknown Facility',
      collectedAt: now,
      updatedAt: now,
    );

    // save via provider (handles offline + online)
    final success = await ref
        .read(patientProvider(widget.role).notifier)
        .addRecord(record);

    if (mounted) {
      setState(() => _submitting = false);
      final online = ref.watch(isOnlineProvider(widget.role));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? online
                      ? 'Patient record saved and uploaded.'
                      : 'Saved offline - will sync when reconnected.'
                : 'Failed to save record.',
          ),
          backgroundColor: success
              ? const Color.fromARGB(255, 3, 5, 4)
              : Colors.redAccent,
        ),
      );
      if (success) {
        // capture paths before resetting
        final savedPaths = List<String>.from(_lesionPhotos.map((f) => f.path));

        _resetForm();
        // increment recordCount
        await _incrementRecord(currentUser.id);

        // savedPaths are now in the Firestore record's clinicalNotes.
        // They'll be uploaded by SyncService or FirestoreService on next push.
        // No further action needed here — the paths are already in the record.
      }
    }
  }

  Future<void> _incrementRecord(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'recordCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('_incrementRecord failed: $e');
    }
  }

  void _resetForm() {
    for (final c in [
      _fullNameCtrl,
      _phoneCtrl,
      _emergNameCtrl,
      _emergContactCtrl,
      _dobCtrl,
      _durationCtrl,
      _examinationDateCtrl,
      _numLesionsCtrl,
      _maxLesionDiamCtrl,
      _modeOtherControl,
      _suspicionOtherCtrl,
      _notesCtrl,
    ]) {
      c.clear();
    }
    _idCtrl.text = 'Tap to generate';
    _locationCtrl.text = 'Tap to generate';
    _lesionPhotos.clear();
    setState(() {
      _selectedSex = null;
      _modeOfDetection = null;
      _classification = null;
      _limitationOfMovement = null;
      _lesionTypes.clear();
      _lesionLocations.clear();
      _clinicalSuspicion.clear();
      _progress = 0.0;
    });
  }

  // -----------------------------------------
  // BUILD
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final online = ref.read(isOnlineProvider(widget.role));

    return SafeArea(
      bottom: false,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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

              // -----------------
              //  SECTION A
              // -----------------
              const _SectionHeader(
                title: 'Patient Identity',
                icon: Icons.person_outline_rounded,
              ),

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
                onTap: _locating ? null : _generateLocation,
                child: AbsorbPointer(
                  child: PillField(
                    controller: _locationCtrl,
                    hint: 'Location: Tap to generate',
                    suffixIcon: _locating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.tealDeep,
                            ),
                          )
                        : const Icon(
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
                    child: _pillDropdown<String>(
                      value: _selectedSex,
                      hint: 'Sex',
                      items: _sexOptions,
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
                hint: 'Emergency Contact Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Emergency Contact
              PillField(
                controller: _emergContactCtrl,
                hint: 'Emergency Contact Number',
                keyboardType: TextInputType.phone,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),

              /* const SizedBox(height: 28),

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
              ), */

              // ---------------
              // SECTION B
              // ---------------
              const _SectionHeader(
                title: 'Detection & Classification',
                icon: Icons.track_changes_rounded,
              ),

              // mode of detection
              Text(
                'Mode of Detection',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _detectionModes,
                selected: _modeOfDetection != null ? {_modeOfDetection!} : {},
                onToggle: (v) {
                  setState(() => _modeOfDetection = v);
                  _updateProgress();
                },
              ),
              if (_modeOfDetection == 'Other') ...[
                const SizedBox(height: 10),
                PillField(
                  controller: _modeOtherControl,
                  hint: 'Specify mode of detection',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 16),

              // Classification
              Text(
                'Patient Classification',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _classificationOptions,
                selected: _classification != null ? {_classification!} : {},
                onToggle: (v) {
                  setState(() => _classification = v);
                  _updateProgress();
                },
              ),

              // -----------------------------
              // SECTION C - Clinical Details
              // -----------------------------
              const _SectionHeader(
                title: 'Clinical Details',
                icon: Icons.medical_information_outlined,
              ),

              // Duration of sickness
              PillField(
                controller: _durationCtrl,
                hint: 'Duration of Sickness (e.g. 3 weeks)',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Date of clinical examination
              GestureDetector(
                onTap: _pickExaminationDate,
                child: AbsorbPointer(
                  child: PillField(
                    controller: _examinationDateCtrl,
                    hint: 'Date of Clinical Examination',
                    suffixIcon: const Icon(
                      Icons.calendar_month_rounded,
                      size: 16,
                      color: AppColors.textMid,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Limitation of movement
              Text(
                'Limitation of Movement',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _limitOptions,
                selected: _limitationOfMovement != null
                    ? {_limitationOfMovement!}
                    : {},
                onToggle: (v) {
                  setState(() => _limitationOfMovement = v);
                  _updateProgress();
                },
              ),
              const SizedBox(height: 16),

              // Number + diameter of lesions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: PillField(
                      controller: _numLesionsCtrl,
                      hint: 'No. of Lesions',
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillField(
                      controller: _maxLesionDiamCtrl,
                      hint: 'Biggest Lesion (cm)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Type of lesion (multi-select)
              Text(
                'Type of Lesion',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _lesionTypeOptions,
                selected: _lesionTypes,
                onToggle: _toggleLesionType,
              ),
              const SizedBox(height: 16),

              // Location of lesion (multi-select)
              Text(
                'Location of Lesion',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _lesionLocationOptions,
                selected: _lesionLocations,
                multiSelect: true,
                onToggle: _toggleLesionLocation,
              ),
              const SizedBox(height: 16),

              // Clinical suspicion (multi-select)
              Text(
                'Clinical Suspicion',
                style: t.labelMedium?.copyWith(
                  color: AppColors.textMid,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _ChipSelector(
                options: _suspicionOptions,
                selected: _clinicalSuspicion,
                multiSelect: true,
                onToggle: _toggleSuspicion,
              ),
              if (_clinicalSuspicion.contains('Other')) ...[
                const SizedBox(height: 10),
                PillField(
                  controller: _suspicionOtherCtrl,
                  hint: 'Specify clinical suspicion',
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],

              // ---------------------------
              // SECTION D - photos, notes
              // ---------------------------
              const _SectionHeader(
                title: 'Photos & Notes',
                icon: Icons.camera_alt_outlined,
              ),

              // Photo grid
              if (_lesionPhotos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (ctx, i) {
                      if (i == _lesionPhotos.length) {
                        // add more button
                        return _addPhotoButton();
                      }
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _lesionPhotos[i],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _lesionPhotos.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: _lesionPhotos.length + 1,
                  ),
                ),
                const SizedBox(height: 12),
              ] else ...[
                _addPhotoButton(fullWidth: true),
                const SizedBox(height: 12),
              ],

              // Additionnal Notes
              TextFormField(
                controller: _notesCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Any other clinical notes...',
                  hintStyle: TextStyle(color: AppColors.textMid, fontSize: 14),
                  filled: true,
                  fillColor: AppColors.fieldBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              // Progress Bar + Submit button
              const SizedBox(height: 32),

              // Progress label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Form completion',
                    style: TextStyle(fontSize: 12, color: AppColors.textMid),
                  ),
                  Text(
                    '${(_progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _progress == 1.0
                          ? AppColors.success
                          : AppColors.textMid,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: AppColors.fieldBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),

              const SizedBox(height: 28),

              // Submit button
              Center(
                child: CircularActionButton(
                  icon: _submitting
                      ? Icons.hourglass_empty_rounded
                      : Icons.check_rounded,
                  onTap: _submitting ? () {} : _submit,
                  size: 62,
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  _submitting
                      ? 'Saving...'
                      : _progress < 1.0
                      ? 'Complete all fields to submit'
                      : 'Ready to submit',
                  style: TextStyle(
                    fontSize: 12,
                    color: _progress == 1.0
                        ? AppColors.success
                        : AppColors.textMid,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Photo add button ---------
  Widget _addPhotoButton({bool fullWidth = false}) {
    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: fullWidth ? double.infinity : 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.fieldBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.tealDeep.withOpacity(0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.tealDeep,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              fullWidth ? 'Add Lesion Photos' : 'Add More',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.tealDeep,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
