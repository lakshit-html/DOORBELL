import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../auth/providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: user?.profileImage != null
                        ? AppNetworkImage(
                            url: user!.profileImage,
                            width: 64,
                            height: 64,
                            borderRadius: 32)
                        : const Icon(Icons.person,
                            size: 36, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'Guest',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9))),
                      if (user?.phone != null)
                        Text(user!.phone!,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _tile(context, Icons.account_balance_wallet_outlined, 'My Wallet',
              () => context.push(AppRoutes.wallet)),
          _tile(context, Icons.location_on_outlined, 'Saved Addresses',
              () => context.push(AppRoutes.addresses)),
          _tile(context, Icons.receipt_long_outlined, 'My Orders',
              () => context.go(AppRoutes.home)),
          _tile(context, Icons.notifications_outlined, 'Notifications',
              () => context.push(AppRoutes.notifications)),
          _tile(context, Icons.help_outline, 'Help & Support', () {}),
          _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {}),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('DoorBell v1.0.0',
                style: TextStyle(color: AppColors.textHint, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title,
          VoidCallback onTap) =>
      Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to log in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign Out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }
}
