import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skinapp2/core/theme/app_theme.dart';
import 'package:skinapp2/features/auth/providers/auth_provider.dart';
import 'package:skinapp2/models/user.dart';
import 'package:skinapp2/shared/widgets/pill_field.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: Column(
        children: [
          // Navy header with tab bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(
              28,
              MediaQuery.of(context).padding.top + 20,
              28,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo row
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.biotech_rounded,
                        color: AppColors.teal,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'SKiN NTD',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Data Collection\nPlatform',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tracking skin NTDs across communities.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.teal,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.4),
                  labelStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Create Account'),
                  ],
                ),
              ],
            ),
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tab,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _LoginTab(onSignUp: () => _tab.animateTo(1)),
                _SignUpTab(onSignIn: () => _tab.animateTo(0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------
// LOGIN TAB
// ------------------------
class _LoginTab extends ConsumerStatefulWidget {
  final VoidCallback onSignUp;
  const _LoginTab({required this.onSignUp});

  @override
  ConsumerState<_LoginTab> createState() => __LoginTabState();
}

class __LoginTabState extends ConsumerState<_LoginTab> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  AccessRole _role = AccessRole.collector;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final ok = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: _role,
        );

    // Router's redirect handles navigation on success
    if (!ok && mounted) {
      // Error already in state - displayed by _ErrorBanner
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loading = authState.loading;
    final error = authState.error;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role selector
            const _SectionLabel(label: 'I am a'),
            const SizedBox(height: 10),
            _RoleSelector(
              selected: _role,
              onChanged: (r) {
                setState(() => _role = r);
                // Clear error when role changes
                ref.read(authProvider.notifier);
              },
            ),
            const SizedBox(height: 20),

            if (error != null) _ErrorBanner(message: error),

            const _SectionLabel(label: 'Email address'),
            const SizedBox(height: 6),
            PillField(
              controller: _emailCtrl,
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            const _SectionLabel(label: 'Password'),
            const SizedBox(height: 6),
            PillField(
              controller: _passCtrl,
              hint: 'Enter your password',
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMid,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required.';
                return null;
              },
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPassword(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealDeep,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tagged email hint - shows what Firebase account will be used
            _TaggedEmailHint(role: _role, emailCtrl: _emailCtrl),
            const SizedBox(height: 20),

            _AuthButton(label: 'Sign In', loading: loading, onTap: _submit),
            const SizedBox(height: 20),

            _SwitchRow(
              question: "Don't have an account?",
              action: 'Sign Up',
              onTap: widget.onSignUp,
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(role: _role),
    );
  }
}

// ---------------------------
// SIGN UP TAB
// ---------------------------
class _SignUpTab extends ConsumerStatefulWidget {
  final VoidCallback onSignIn;
  const _SignUpTab({required this.onSignIn});

  @override
  ConsumerState<_SignUpTab> createState() => __SignUpTabState();
}

class __SignUpTabState extends ConsumerState<_SignUpTab> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _facilityCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  AccessRole _role = AccessRole.collector;
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _termsAccepted = false;
  double _passStrength = 0;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(
      () => setState(() => _passStrength = _calcStrength(_passCtrl.text)),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _facilityCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  double _calcStrength(String p) {
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (p.length >= 12) s += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.2;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) s += 0.2;
    return s.clamp(0.0, 1.0);
  }

  Color get _strengthColor {
    if (_passStrength < 0.4) return AppColors.error;
    if (_passStrength < 0.7) return AppColors.warning;
    return AppColors.success;
  }

  String get _strengthLabel {
    if (_passStrength == 0) return '';
    if (_passStrength < 0.4) return 'Weak';
    if (_passStrength < 0.7) return 'Fair';
    if (_passStrength < 0.9) return 'Good';
    return 'Strong';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final ok = await ref
        .read(authProvider.notifier)
        .signUp(
          fullName: _fullNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: _role,
          facilityName: _facilityCtrl.text.trim(),
        );

    if (ok && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        email: _emailCtrl.text.trim(),
        role: _role,
        onContinue: () {
          Navigator.of(context).pop();
          // Router redirect fires automatically - user lands on /home
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loading = authState.loading;
    final error = authState.error;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel(label: 'I am registering as'),
            const SizedBox(height: 10),
            _RoleSelector(
              selected: _role,
              onChanged: (r) => setState(() => _role = r),
            ),
            const SizedBox(height: 8),
            _RoleInfoBox(role: _role),
            const SizedBox(height: 20),

            if (error != null) _ErrorBanner(message: error),

            const _SectionLabel(label: 'Full Name'),
            const SizedBox(height: 6),
            PillField(
              controller: _fullNameCtrl,
              hint: 'e.g. Akosua Mensah',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Full name is required';
                if (v.trim().split(' ').length < 2) {
                  return 'Enter your first and last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            const _SectionLabel(label: 'Email Address'),
            const SizedBox(height: 6),
            PillField(
              controller: _emailCtrl,
              hint: 'your@email.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 18),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            _TaggedEmailHint(role: _role, emailCtrl: _emailCtrl),
            const SizedBox(height: 14),

            const _SectionLabel(label: 'Facility / Institution'),
            const SizedBox(height: 6),
            PillField(
              controller: _facilityCtrl,
              hint: 'e.g. Korle Bu Teaching Hospital',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.local_hospital_outlined, size: 18),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Facility name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            const _SectionLabel(label: 'Password'),
            const SizedBox(height: 6),
            PillField(
              controller: _passCtrl,
              hint: 'Min. 8 characters',
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMid,
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (_passStrength < 0.4) {
                  return 'Too weak - add uppercase letters, numbers, or symbols';
                }
                return null;
              },
            ),

            // Password strength indicator
            if (_passCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passStrength,
                        minHeight: 5,
                        backgroundColor: AppColors.fieldBg,
                        valueColor: AlwaysStoppedAnimation(_strengthColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _strengthLabel,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _strengthColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _PassHint(label: '8+ chars', met: _passCtrl.text.length >= 8),
                  _PassHint(
                    label: 'Uppercase',
                    met: RegExp(r'[A-Z]').hasMatch(_passCtrl.text),
                  ),
                  _PassHint(
                    label: 'Number',
                    met: RegExp(r'[0-9]').hasMatch(_passCtrl.text),
                  ),
                  _PassHint(
                    label: 'Symbol',
                    met: RegExp(r'[!@#\$%^&*]').hasMatch(_passCtrl.text),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),

            const _SectionLabel(label: 'Confirm password'),
            const SizedBox(height: 6),
            PillField(
              controller: _confirmCtrl,
              hint: 'Re-enter your password',
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConf = !_obscureConf),
                icon: Icon(
                  _obscureConf
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.textMid,
                ),
              ),
              validator: (v) {
                if (v != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Terms checkbox
            GestureDetector(
              onTap: () => setState(() => _termsAccepted = !_termsAccepted),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _termsAccepted
                          ? AppColors.navy
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _termsAccepted
                            ? AppColors.navy
                            : AppColors.textHint,
                        width: 1.5,
                      ),
                    ),
                    child: _termsAccepted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I agree that patient data will be handled according to applicable health data regulations and institutional policies.',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        color: AppColors.textMid,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _AuthButton(
              label: 'Create Account',
              loading: loading,
              onTap: _submit,
            ),
            const SizedBox(height: 20),
            _SwitchRow(
              question: 'Already have an account?',
              action: 'Sign In',
              onTap: widget.onSignIn,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------
// FORGOT PASSWORD SHEET
// --------------------------
class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  final AccessRole role;
  const _ForgotPasswordSheet({required this.role});

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      __ForgotPasswordSheetState();
}

class __ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AccessRole _role;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _role = widget.role;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authProvider.notifier)
        .sendPasswordReset(email: _emailCtrl.text.trim(), role: _role);
    if (ok && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authProvider).loading;
    final error = ref.watch(authProvider).error;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset Password',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _sent
                  ? 'Check your inbox for the reset link.'
                  : 'Select your role and enter your email.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: AppColors.textMid,
              ),
            ),
            const SizedBox(height: 20),
            if (!_sent) ...[
              if (error != null) _ErrorBanner(message: error),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'Role'),
                    const SizedBox(height: 8),
                    _RoleSelector(
                      selected: _role,
                      onChanged: (r) => setState(() => _role = r),
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel(label: 'Email address'),
                    const SizedBox(height: 6),
                    PillField(
                      controller: _emailCtrl,
                      hint: 'your@email.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 18,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _AuthButton(
                      label: 'Send Reset Link',
                      loading: loading,
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mark_email_read_outlined,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reset email sent! Check your inbox and spam folder.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AuthButton(
                label: 'Done',
                loading: false,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// -------------------------------
// SUCCESS DIALOG - after signUp
// -------------------------------
class _SuccessDialog extends StatelessWidget {
  final String email;
  final AccessRole role;
  final VoidCallback onContinue;

  const _SuccessDialog({
    required this.email,
    required this.role,
    required this.onContinue,
  });

  String get _tagged {
    if (!email.contains('@')) return email;
    final p = email.split('@');
    return '${p[0]}+${role.name}@${p[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 32,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Account Created!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textNavy,
              ),
            ),
            const SizedBox(height: 12),

            // Verification Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A verification email was sent to $email. Please verify before signing in.',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tagged email to save
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save your sign-in email:',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _tagged,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'User this email + your password + same role to sign in.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _AuthButton(
              label: 'Continue to App',
              loading: false,
              onTap: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------
// shared widgets
// --------------------------------
class _RoleSelector extends StatelessWidget {
  final AccessRole selected;
  final ValueChanged<AccessRole> onChanged;

  const _RoleSelector({required this.selected, required this.onChanged});

  Color _color(AccessRole r) {
    switch (r) {
      case AccessRole.collector:
        return AppColors.roleCollector;
      case AccessRole.physician:
        return AppColors.rolePhysician;
      case AccessRole.researcher:
        return AppColors.roleResearcher;
    }
  }

  IconData _icon(AccessRole r) {
    switch (r) {
      case AccessRole.collector:
        return Icons.assignment_ind_outlined;
      case AccessRole.physician:
        return Icons.local_hospital_outlined;
      case AccessRole.researcher:
        return Icons.science_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AccessRole.values.map((role) {
        final sel = role == selected;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: sel ? AppColors.navy : AppColors.bgWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? AppColors.navy : AppColors.fieldBg,
                  width: sel ? 2 : 1,
                ),
                boxShadow: sel
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icon(role),
                    size: 20,
                    color: sel ? AppColors.teal : _color(role),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    role.label.split(' ').last, // gives role
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.textMid,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoleInfoBox extends StatelessWidget {
  final AccessRole role;

  const _RoleInfoBox({required this.role});

  static const _info = {
    AccessRole.collector:
        'Collects patient demographic and clinical data in the field.',
    AccessRole.physician: 'Reviews collected data and adds clinical diagnoses.',
    AccessRole.researcher:
        'Full read access with timestamps and data export capabilities.',
  };

  Color _color(AccessRole r) {
    switch (r) {
      case AccessRole.collector:
        return AppColors.roleCollector;
      case AccessRole.physician:
        return AppColors.rolePhysician;
      case AccessRole.researcher:
        return AppColors.roleResearcher;
    }
  }

  IconData _icon(AccessRole r) {
    switch (r) {
      case AccessRole.collector:
        return Icons.assignment_ind_outlined;
      case AccessRole.physician:
        return Icons.local_hospital_outlined;
      case AccessRole.researcher:
        return Icons.science_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: ValueKey(role),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _color(role).withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color(role).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(_icon(role), size: 15, color: _color(role)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _info[role]!,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _color(role),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaggedEmailHint extends StatefulWidget {
  final AccessRole role;
  final TextEditingController emailCtrl;

  const _TaggedEmailHint({required this.role, required this.emailCtrl});

  @override
  State<_TaggedEmailHint> createState() => __TaggedEmailHintState();
}

class __TaggedEmailHintState extends State<_TaggedEmailHint> {
  @override
  void initState() {
    super.initState();
    widget.emailCtrl.addListener(() => setState(() {}));
  }

  String get _tagged {
    final email = widget.emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return '';
    final parts = email.split('@');
    return '${parts[0]}+${widget.role.name}@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final tagged = _tagged;
    if (tagged.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tealDeep.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: AppColors.tealDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: AppColors.textMid,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Firebase account: '),
                  TextSpan(
                    text: tagged,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textNavy,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _AuthButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String question;
  final String action;
  final VoidCallback onTap;
  const _SwitchRow({
    required this.question,
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.textMid,
            ),
            children: [
              TextSpan(text: '$question '),
              TextSpan(
                text: action,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.tealDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassHint extends StatelessWidget {
  final String label;
  final bool met;
  const _PassHint({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 12,
          color: met ? AppColors.success : AppColors.textHint,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: met ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
