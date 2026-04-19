// ------------------------------------
// VIEW DATA SCREEN
// ------------------------------------
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

class ViewDataScreen extends StatefulWidget {
  final AccessRole role;
  const ViewDataScreen({super.key, required this.role});

  @override
  State<ViewDataScreen> createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends State<ViewDataScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedDate;
  List<PatientRecord> _filtered = List.from(kMockPatients);

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = kMockPatients.where((p) {
        return p.fullName.toLowerCase().contains(q) ||
            p.idNumber.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        _selectedDate =
            '${picked.day}-${months[picked.month - 1]}-${picked.year}';
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TItle + refresh
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text('View\nPatient\nData', style: t.pageTitle),
                ),
                CircularActionButton(
                  icon: Icons.refresh_rounded,
                  onTap: _filter,
                  size: 50,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search + date filter
            SearchDateRow(
              searchCtrl: _searchCtrl,
              onDateTap: _pickDate,
              selectedDate: _selectedDate,
            ),
            const SizedBox(height: 16),

            // List
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
                              editMode: false,
                            ),
                          ),
                        ),
                        showTimestamp: widget.role.canViewTimestamps,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
