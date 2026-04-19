import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/models/diagnosis.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/bottom_navbar.dart';
import 'package:skinapp2/shared/widgets/datetime_welcome_card.dart';
import 'package:skinapp2/shared/widgets/ntd_info_card.dart';
import 'package:skinapp2/shared/widgets/role_badge.dart';

// --------------------------------------------
// HOME SCREEN
// Tab 0 = Home
// Tab 1 = Add Patient
// Tab 2 = View data
// Tab 3 = Manage data
// --------------------------------------------

class HomeScreen extends StatefulWidget {
  final AccessRole role;
  const HomeScreen({super.key, required this.role});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _HomeTab(role: widget.role),
      if (widget.role == AccessRole.collector)
        AddPatientScreen(role: widget.role)
      else
        ViewDataScreen(role: widget.role),
      ViewDataScreen(role: widget.role),
      ManageDataScreen(role: widget.role),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: IndexedStack(index: _tab, children: _pages),
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: SkinNavBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          role: widget.role,
        ),
      ),
    );
  }
}

// -----------------------------------------------
// home tab - welcome + date/time card + ntd info
// -----------------------------------------------
class _HomeTab extends StatelessWidget {
  final AccessRole role;
  const _HomeTab({required this.role});

  // Rotating NTD info snippets
  static const _ntdInfo = [
    (
      type: SkinNtdType.buruliUlcer,
      desc:
          'A chronic, necrotizing skin disease caused by *Mycobacterium ulcerans*, leading to painless ulcers that can cause severe tissue damage if left untreated.',
    ),
    (
      type: SkinNtdType.leprosy,
      desc:
          'A chronic infectious disease caused by *Mycobacterium leprae* that primarily affects the skin, peripheral nerves, and eyes.',
    ),
    (
      type: SkinNtdType.yaws,
      desc:
          'A tropical infection of the skin, bones, and joints caused by *Treponemapallidum pertenue*, mostly affecting children.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome!', style: t.displaySmall),
                    const SizedBox(height: 2),
                    RoleBadge(role: role),
                  ],
                ),
                GestureDetector(
                  onTap: () {}, // profile
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.navy,
                    child: const Text(
                      'AK',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Date/time card
            const DatetimeWelcomeCard(),

            const SizedBox(height: 20),

            // NTD info cards in horizontal scroll
            Text('Know Your NTDs', style: t.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              child: ListView.separated(
                itemBuilder: (ctx, i) {
                  final info = _ntdInfo[i];
                  return SizedBox(
                    width: 260,
                    child: NtdInfoCard(type: info.type, description: info.desc),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: _ntdInfo.length,
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            Text('Quick Actions', style: t.titleMedium),
            const SizedBox(height: 12),
            if (role == AccessRole.collector)
              _QuickActionCard(
                icon: Icons.person_add_outlined,
                title: 'Add New Patient',
                subtitle: 'Record patient NTD data',
                onTap: () {},
                accent: AppColors.navy,
              ),
            if (role.canViewRawLocation) ...[
              const SizedBox(height: 10),
              _QuickActionCard(
                icon: Icons.description_outlined,
                title: 'View Records',
                subtitle: 'Browse all patient submissions',
                onTap: () {},
                accent: AppColors.tealDeep,
              ),
            ],
            if (role.canDiagnose) ...[
              const SizedBox(height: 10),
              _QuickActionCard(
                icon: Icons.edit_note_rounded,
                title: 'Pending Diagnoses',
                subtitle: 'Patients awaiting diagnosis',
                onTap: () {},
                accent: AppColors.warning,
              ),
            ],
            if (role.canExport) ...[
              const SizedBox(height: 10),
              _QuickActionCard(
                icon: Icons.download_rounded,
                title: 'Export Data',
                subtitle: 'Download CSV or PDF',
                onTap: () {},
                accent: AppColors.roleResearcher,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textNavy,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
