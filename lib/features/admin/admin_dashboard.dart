// models
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/services/firestore_service.dart';
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
  String? _error;

  List<_AppUser> _collectors = [];
  List<_AppUser> _physicians = [];
  List<_AppUser> _researchers = [];
  _Stats? _stats;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
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

        // detection mode
        final mode = clinical['modeOfDetection'] as String? ?? 'Unknown';
        byDetection[mode] = (byDetection[mode] ?? 0) + 1;
      }

      setState(() {
        _collectors = users.where((u) => u.role == 'collector').toList();
        _physicians = users.where((u) => u.role == 'physician').toList();
        _researchers = users.where((u) => u.role == 'researcher').toList();
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

  // delete user
  Future<void> _deleteUser(_AppUser user) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} removed'),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove user: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Map<String, dynamic> _parseJson(String s) {
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
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
                        Text('Admin\nDashboard', style: t.pageTitle),
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
                  Material(
                    color: AppColors.navy,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _load,
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
          ],
        ),
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
        ..._sorted(stats.bySuspicion).map(
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
