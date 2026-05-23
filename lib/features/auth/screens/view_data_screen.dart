// ------------------------------------
// VIEW DATA SCREEN
// ------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/patient_provider.dart';
import 'package:skinapp2/features/auth/screens/patient_detail_screen.dart';
import 'package:skinapp2/models/patient.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/circular_action_btn.dart';
import 'package:skinapp2/shared/widgets/empty_state.dart';
import 'package:skinapp2/shared/widgets/patient_list_row.dart';
import 'package:skinapp2/shared/widgets/search_date_filter_row.dart';

class ViewDataScreen extends ConsumerStatefulWidget {
  final AccessRole role;
  const ViewDataScreen({super.key, required this.role});

  @override
  ConsumerState<ViewDataScreen> createState() => _ViewDataScreenState();
}

class _ViewDataScreenState extends ConsumerState<ViewDataScreen> {
  final _searchCtrl = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedDateLabel;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final state = ref.watch(patientProvider(widget.role));
    final online = state.online;
    final filtered = _applyFilters(state.records);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        // online badge
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
                        // Refresh
                        CircularActionButton(
                          icon: Icons.refresh_rounded,
                          onTap: () {
                            ref
                                .read(patientProvider(widget.role).notifier)
                                .syncNow();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Sync complete.')),
                              );
                            }
                          },
                          size: 42,
                        ),
                      ],
                    ),

                    // unsynced badge for collector
                    if (widget.role.isCollector && state.unsyncedCount > 0) ...[
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
                          '${state.unsyncedCount} pending sync',
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

            // physician/researcher notice
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
                        'Showing synced records only',
                        style: TextStyle(fontSize: 12, color: AppColors.navy),
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

            if (_selectedDateLabel != null) ...[
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

            // summary row
            if (state.records.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Total',
                      value: '${state.records.length}',
                      color: AppColors.navy,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Pending',
                      value:
                          '${state.records.where((p) => !p.hasDiagnosis).length}',
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Diagnosed',
                      value:
                          '${state.records.where((p) => p.hasDiagnosis).length}',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: state.loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? EmptyState(
                      title: 'No records found',
                      subtitle:
                          _searchCtrl.text.isNotEmpty || _selectedDate != null
                          ? 'Try adjusting your search or date filter.'
                          : widget.role.isCollector
                          ? 'No records saved yet. '
                                'Add a patient to get started.'
                          : 'No synced records available yet.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => PatientListRow(
                        patient: filtered[i],
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PatientDetailScreen(
                              patient: filtered[i],
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

// small stat chip
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
