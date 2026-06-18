import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text, _password.text);
    if (!ok && mounted) {
      final err = ref.read(authControllerProvider).error;
      AppSnackbar.error(
          context, err is Failure ? err.message : 'Login failed');
    }
  }

  Future<void> _google() async {
    // Google Sign-In (google_sign_in v7+) only works on Android.
    if (!Platform.isAndroid) {
      _showGoogleAndroidOnly();
      return;
    }
    final ok =
        await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (!ok && mounted) {
      final err = ref.read(authControllerProvider).error;
      if (err is Failure && err.code == 'cancelled') return;
      AppSnackbar.error(
          context, err is Failure ? err.message : 'Google sign-in failed');
    }
  }

  void _showGoogleAndroidOnly() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.android, color: Color(0xFF3DDC84)),
            SizedBox(width: 8),
            Text('Android Only'),
          ],
        ),
        content: const Text(
          'Google Sign-In is currently available on Android only.\n\n'
          'Please use email & password or phone number to sign in on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push(AppRoutes.phoneLogin);
            },
            child: const Text('Sign in with Phone'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Container(
                  height: 80,
                  width: 80,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.doorbell_rounded,
                      color: Colors.white, size: 42),
                ),
                const SizedBox(height: 24),
                Text('Welcome back',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Sign in to continue to ${AppConstants.appName}',
                  style:
                      const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  hint: '••••••',
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  validator: Validators.password,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      // Show subtle Android badge so users know it's Android-only
                      onPressed: loading ? null : _google,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      onPressed: () =>
                          context.push(AppRoutes.phoneLogin),
                    ),
                  ),
                ]),
                // Android-only hint shown on non-Android devices
                if (!Platform.isAndroid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.android,
                            size: 13, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          'Google sign-in is for Android',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.signup),
                      child: const Text('Sign up',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
