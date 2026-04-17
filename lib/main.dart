import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AppUser? user) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authed = user != null;
      final onAuth =
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/onboarding' ||
          state.matchedLocation == '/login';
      if (!authed && !onAuth) return '/login';
      if (authed && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/home',
        builder: (_, __) =>
            HomeScreen(role: user?.role ?? AccessRole.collector),
      ),
    ],
  );
}

// main
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkinNtdApp());
}

class SkinNtdApp extends StatelessWidget {
  const SkinNtdApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with riverpod authprovider
    // using null for unathenticated state (will redirect to /splash -> /login)
    const AppUser? currentUser = null;

    return MaterialApp.router(
      title: 'SKiN NTD',
      theme: AppTheme.light,
      routerConfig: createRouter(currentUser),
      debugShowCheckedModeBanner: false,
    );
  }
}
