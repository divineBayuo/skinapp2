// -- Auth state ---------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/models/user.dart';

class AuthState {
  final AppUser? user;
  final bool loading;
  final bool initialising; // true during cold-start
  final String? error;

  const AuthState({
    this.user,
    this.loading = false,
    this.initialising = true, // starts true - splash waits for this
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? loading,
    bool? initialising,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      initialising: initialising ?? this.initialising,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// -- Auth notifier --------
class AuthNotifier extends Notifier<AuthState> {
  /* AuthNotifier() : super(const AuthState()) {
    _restore();
  } */

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  @override
  AuthState build() {
    // build() is the Riverpod 3.x equivalent of the constructor
    // Schedule _restore() as a microtask so build() returns the initial
    // state immediately, then the async restore updates state afterwards
    Future.microtask(_restore);
    return const AuthState(); // initialising true
  }

  // --Cold-start: check if a Firebase session already exists
  Future<void> _restore() async {
    debugPrint('🔄 _restore() started');
    try {
      final firebaseUser = _auth.currentUser;
      debugPrint('👤 Firebase user: $firebaseUser');

      if (firebaseUser != null) {
        debugPrint('📄 Fetching Firestore doc for ${firebaseUser.uid}');
        final appUser = await _fetchUserDoc(firebaseUser.uid);
        debugPrint('✅ User doc fetched: ${appUser.fullName}');
        state = state.copyWith(user: appUser, initialising: false);
      } else {
        debugPrint('⚪ No current user — setting initialising: false');
        state = state.copyWith(initialising: false);
      }
    } catch (e, stack) {
      debugPrint('❌ _restore() error: $e');
      debugPrint('📍 Stack: $stack');
      // If anything fails (e.g. no network), treat as logged out
      state = state.copyWith(initialising: false);
    }
    debugPrint(
      '🏁 _restore() done — initialising is now: ${state.initialising}',
    );
  }

  // --- fetch /users/{uid} doc from Firestoreuser
  Future<AppUser> _fetchUserDoc(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) {
      throw FirebaseAuthException(code: 'user-doc-missing');
    }
    return AppUser.fromMap({'id': uid, ...doc.data()!});
  }

  // -- SIGN UP-------
  // Tag the email with the role before registering in FIrebase Auth
  // plain email stored separately in Firestore
  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    required AccessRole role,
    required String facilityName,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final taggedEmail = _tagEmail(email, role);
      debugPrint('Signing up: $taggedEmail');

      // 1. Create Firebase auth account with tagged email
      final cred = await _auth.createUserWithEmailAndPassword(
        email: taggedEmail,
        password: password,
      );

      // 2. Set display name
      await cred.user!.updateDisplayName(fullName);

      // sendEmailVerification can fail on web during local dev
      // Firebase blocks unverified domains, so wrap so it never crashes
      try {
        await cred.user!.sendEmailVerification();
        debugPrint('Verification email sent');
      } catch (e) {
        debugPrint('sendEmailVerification skipped: e');
      }

      // 3. Send email verification
      // await cred.user!.sendEmailVerification();

      // 4. Write user doc to Firestore
      final now = DateTime.now();
      await _db.collection('users').doc(cred.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'taggedEmail': taggedEmail,
        'role': role.name,
        'facilityName': facilityName,
        'createdAt': now.toIso8601String(),
        'isActive': true,
      });

      debugPrint('Sign up success for $taggedEmail');
      state = state.copyWith(
        loading: false,
        user: AppUser(
          id: cred.user!.uid,
          fullName: fullName,
          email: email,
          role: role,
          facilityName: facilityName,
          createdAt: now,
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp FirebaseAuthException: ${e.code}');
      state = state.copyWith(loading: false, error: _mapError(e.code));
      return false;
    } catch (e) {
      debugPrint('SignUp unknown error: $e');
      state = state.copyWith(
        loading: false,
        error: 'Sign up failed. Please try again.',
      );
      return false;
    }
  }

  // --- LOGIN ----------------------
  // User provides plain email + role -> app reconstructs tagged -> Firebase
  Future<bool> login({
    required String email,
    required String password,
    required AccessRole role,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final taggedEmail = _tagEmail(email, role);
      debugPrint('Logging in: $taggedEmail');

      final cred = await _auth.signInWithEmailAndPassword(
        email: taggedEmail,
        password: password,
      );

      final appUser = await _fetchUserDoc(cred.user!.uid);
      debugPrint('Login success: ${appUser.fullName}');
      state = state.copyWith(user: appUser, loading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login FirebaseAuthException: ${e.code}');
      state = state.copyWith(loading: false, error: _mapError(e.code));
      return false;
    } catch (e) {
      debugPrint('Login unknown error: $e');
      state = state.copyWith(
        loading: false,
        error: 'Sign in failed. Check your details and try again.',
      );
      return false;
    }
  }

  // --- FORGOT PASSWORD ---------
  Future<bool> sendPasswordReset({
    required String email,
    required AccessRole role,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _auth.sendPasswordResetEmail(email: _tagEmail(email, role));
      state = state.copyWith(loading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(loading: false, error: _mapError(e.code));
      return false;
    }
  }

  // --- LOGOUT ---------------
  Future<void> logout() async {
    await _auth.signOut();
    // Keep initialising: false so router doesn't go back to splash
    debugPrint('Logged out');
    state = const AuthState(initialising: false);
  }

  // --- Helpers --------------
  String _tagEmail(String email, AccessRole role) {
    final parts = email.trim().split('@');
    if (parts.length != 2) return email;
    return '${parts[0]}+${role.name}@${parts[1]}';
  }

  String _mapError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists for this email and role. Sign in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 8 characters.';
      case 'user-not-found':
      case 'invalid-credential':
        return 'No account found. Check your email, role selection, and password';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Contact your administrator.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'user-doc-missing':
        return 'Account data missing. Please contact your administrator.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// -- Providers --------
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

final userRoleProvider = Provider<AccessRole>((ref) {
  return ref.watch(currentUserProvider)?.role ?? AccessRole.collector;
});
