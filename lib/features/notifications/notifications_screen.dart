import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/providers/auth_providers.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final uid = ref.watch(currentUidProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (uid != null)
            TextButton(
              onPressed: () => ref
                  .read(notificationRepositoryProvider)
                  .markAllRead(uid),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: notifications.when(
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'No notifications',
                subtitle: 'Order updates and offers will show up here.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final n = list[i];
                  return ListTile(
                    onTap: () => ref
                        .read(notificationRepositoryProvider)
                        .markRead(n.notificationId),
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primaryLight.withValues(alpha: 0.3),
                      child: Icon(
                        n.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight: n.isRead
                                ? FontWeight.w500
                                : FontWeight.w800)),
                    subtitle: Text(n.body),
                    trailing: n.createdAt != null
                        ? Text(Formatters.relativeTime(n.createdAt!),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textHint))
                        : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}
