import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/admin/admin_dashboard.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<IdTokenResult>(
      // force-refresh so we always get latest custom claims
      future: FirebaseAuth.instance.currentUser?.getIdTokenResult(true),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final claims = snap.data?.claims ?? {};
        if (claims['role'] == 'admin') {
          return const AdminDashboardScreen();
        }
        // Not admin - send them back
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 48, color: AppColors.textMid),
                const SizedBox(height: 12),
                const Text(
                  'Access denied',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Admin access only.',
                  style: TextStyle(color: AppColors.textMid),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
