import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_providers.dart';

/// Brand splash. While auth resolves, the GoRouter redirect forwards
/// authenticated users to their role home. Unauthenticated users land here and
/// we route them to onboarding (first launch) or login.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    // If the user is logged in, the router redirect already handles forwarding.
    final loggedIn = ref.read(authStateProvider).value != null;
    if (loggedIn) return;

    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool(AppConstants.prefsOnboardingDone) ?? false;
    if (!mounted) return;
    context.go(onboarded ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    size: 72, color: AppColors.primary),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fadeIn(),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              const SizedBox(height: 8),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
