// -- Role Gate ----
// Reads the authenticated user's role and renders the correct home_screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skinapp2/features/admin/admin_dashboard.dart';
import 'package:skinapp2/features/auth/providers/auth_provider.dart';
import 'package:skinapp2/features/auth/screens/auth_screen.dart';
import 'package:skinapp2/features/auth/screens/home_screen.dart';
import 'package:skinapp2/features/auth/screens/onboarding_screen.dart';
import 'package:skinapp2/features/auth/screens/splash_screen.dart';

class RoleGate extends ConsumerWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return HomeScreen(role: user.role);
  }
}

// ---------------------------------------------------------------------------
// auth listenable - standalone Changenotifier kept alive by its own provider
// ---------------------------------------------------------------------------
class AuthListenable extends ChangeNotifier {
  AuthListenable(Ref ref) {
    // listen to the auth provider - fires on every state change
    ref.listen<AuthState>(authProvider, (previous, next) {
      debugPrint(
        'AuthListenable - innitialising: ${next.initialising},'
        'authed: ${next.isAuthenticated}',
      );
      notifyListeners();
    });
  }
}

// keep alive so it's never recreated
final authListenableProvider = Provider<AuthListenable>((ref) {
  final notifier = AuthListenable(ref);
  // Dispose when the provider is removed
  ref.onDispose(notifier.dispose);
  return notifier;
});

// -- Router Provider ---------
// A Riverpod provider so the router rebuilds whenever auth state changes
final routerProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(authListenableProvider);

  final router = GoRouter(
    initialLocation: '/splash',

    // GoRouter calls redirect on every navigation event
    // We also trigerr a refresh whenever auth state changes via the notifier
    refreshListenable: authListenable,

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loc = state.matchedLocation;

      debugPrint(
        'redirect - loc: $loc | '
        'initialising: ${authState.initialising} | '
        'authed: ${authState.isAuthenticated}',
      );

      // While restoring session, stay on splash
      if (authState.initialising) {
        return loc == '/splash' ? null : '/splash';
      }

      final authed = authState.isAuthenticated;
      final onPublic =
          loc == '/splash' || loc == '/onboarding' || loc == '/login';

      if (!authed && !onPublic) return '/login';
      if (!authed && loc == '/splash') return '/onboarding';
      if (authed && onPublic) return '/home';
      return null;
    },

    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/home', builder: (_, __) => const RoleGate()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

// --Auth Change notifier--------
// wrap Riverpod listener into a Changenotifier so GoROuter can refresh
/* class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
  }
} */
