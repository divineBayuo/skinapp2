// -----------------------------------
// MANAGE DATA SCREEN
// -----------------------------------
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/screens/patient_detail_screen.dart';
import 'package:skinapp2/mock_data.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/empty_state.dart';
import 'package:skinapp2/shared/widgets/patient_list_row.dart';
import 'package:skinapp2/shared/widgets/search_date_filter_row.dart';

class ManageDataScreen extends StatefulWidget {
  final AccessRole role;
  const ManageDataScreen({super.key, required this.role});

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedDate;
  List<PatientRecord> _filtered = List.from(kMockPatients);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase();
      setState(() {
        _filtered = kMockPatients
            .where(
              (p) =>
                  p.fullName.toLowerCase().contains(q) ||
                  p.idNumber.toLowerCase().contains(q),
            )
            .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final canSave = widget.role.canExport || widget.role.canDiagnose;

    return SafeArea(
      bottom: false,
      child: Padding(
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
                // Red save/export FAB
                if (canSave)
                  CircularActionButton(
                    icon: Icons.save_alt_rounded,
                    onTap: () {}, // export or save actions
                    bgColor: widget.role.canExport
                        ? AppColors.saveRed
                        : AppColors.navy,
                    size: 50,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            SearchDateRow(
              searchCtrl: _searchCtrl,
              onDateTap: () {},
              selectedDate: _selectedDate,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filtered.isEmpty
                  ? const EmptyState(
                      title: 'No records found',
                      subtitle: 'Try adjusting your search.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => PatientListRow(
                        patient: _filtered[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(
                              patient: _filtered[i],
                              role: widget.role,
                              editMode: true,
                            ),
                          ),
                        ),
                        showTimestamp: true,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
