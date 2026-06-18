import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/enums.dart';
import '../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  UserRole _role = UserRole.customer;

  static const _selectableRoles = [
    (UserRole.customer, Icons.person_outline, 'Customer'),
    (UserRole.shopOwner, Icons.storefront_outlined, 'Shop Owner'),
    (UserRole.rider, Icons.delivery_dining_outlined, 'Rider'),
  ];

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(authControllerProvider.notifier).signUp(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
          phone: _phone.text.trim(),
        );
    if (!ok && mounted) {
      final err = ref.read(authControllerProvider).error;
      AppSnackbar.error(
          context, err is Failure ? err.message : 'Sign up failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I want to join as',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: _selectableRoles.map((r) {
                    final selected = _role == r.$1;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = r.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(r.$2,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.primary),
                              const SizedBox(height: 8),
                              Text(r.$3,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Full Name',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Phone',
                  controller: _phone,
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: Validators.phone,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: _password,
                  prefixIcon: Icons.lock_outline,
                  obscure: true,
                  validator: Validators.password,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Create Account',
                  isLoading: loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.pop(),
                    child: const Text('Already have an account? Sign in',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
