// -- Auth state ---------
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:skinapp2/models/user.dart';

class AuthState {
  final AppUser? user;
  final bool loading;
  final String? error;

  const AuthState({this.user, this.loading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -- Auth notifier --------
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(loading: true);
    // TODO: check FirebaseAuth.instance.currentUser
    // If session token valid -> fetch Firestoreuser decoration -> set state
    await Future.delayed(const Duration(milliseconds: 300));
    state = state.copyWith(loading: false);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      // TODO: Replace mock with Firebase clinicalNotes
      // final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      // final doc = await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).get();
      // final user = AppUser.fromMap({'id': cred.user!.uid, ...doc.data()!});

      await Future.delayed(const Duration(milliseconds: 600));

      // Mock: derive role from email domain for dev
      final role = email.contains('researcher')
          ? AccessRole.researcher
          : email.contains('physician') || email.contains('doctor')
          ? AccessRole.physician
          : AccessRole.collector;

      state = state.copyWith(
        loading: false,
        user: AppUser(
          id: 'mock-uid-001',
          fullName: 'Akosua Mensah',
          email: email,
          role: role,
          facilityName: 'Korle Bu Teaching Hospital',
          createdAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _friendlyError(e.toString()),
      );
      return false;
    }
  }

  Future<void> logout() async {
    // TODO: FirebaseAuth.instance.signOut();
    state = const AuthState();
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found')) {
      return 'No account found for this email.';
    }
    if (raw.contains('wrong-password')) return 'Incorrect password. Try again.';
    if (raw.contains('too-many-requests')) {
      return 'Too many attempts. Wait a moment.';
    }
    if (raw.contains('network')) return 'No internet connection.';
    return 'Sign-in failed. Please try again.';
  }
}

// -- Provide
//rs --------
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final userRoleProvider = Provider<AccessRole>((ref) {
  return ref.watch(currentUserProvider)?.role ?? AccessRole.collector;
});
