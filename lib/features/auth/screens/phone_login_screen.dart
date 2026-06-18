import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// Two-step phone OTP login. Step 1 sends the code; step 2 confirms it.
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  final _name = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  String? _verificationId;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (Validators.phone(_phone.text) != null) {
      AppSnackbar.error(context, 'Enter a valid 10-digit number');
      return;
    }
    setState(() => _loading = true);
    await ref.read(authRepositoryProvider).verifyPhone(
          phoneNumber: '+91${_phone.text.trim()}',
          codeSent: (id) {
            if (!mounted) return;
            setState(() {
              _verificationId = id;
              _codeSent = true;
              _loading = false;
            });
            AppSnackbar.info(context, 'OTP sent to your phone');
          },
          onError: (e) {
            if (!mounted) return;
            setState(() => _loading = false);
            AppSnackbar.error(context, e);
          },
        );
  }

  Future<void> _confirm() async {
    if (_otp.text.trim().length < 6) {
      AppSnackbar.error(context, 'Enter the 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    final ok = await ref.read(authControllerProvider.notifier).confirmOtp(
          verificationId: _verificationId!,
          smsCode: _otp.text.trim(),
          name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      final err = ref.read(authControllerProvider).error;
      AppSnackbar.error(
          context, err is Failure ? err.message : 'Verification failed');
    }
    // On success the router redirect forwards to the role home.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Icon(Icons.sms_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              if (!_codeSent) ...[
                AppTextField(
                  label: 'Mobile Number',
                  controller: _phone,
                  hint: '10-digit number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Send OTP',
                  isLoading: _loading,
                  onPressed: _sendCode,
                ),
              ] else ...[
                AppTextField(
                  label: 'Name (new users)',
                  controller: _name,
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Enter OTP',
                  controller: _otp,
                  hint: '6-digit code',
                  prefixIcon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Verify & Continue',
                  isLoading: _loading,
                  onPressed: _confirm,
                ),
                TextButton(
                  onPressed: _loading ? null : _sendCode,
                  child: const Text('Resend OTP'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
