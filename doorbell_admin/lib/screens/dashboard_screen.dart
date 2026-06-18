import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/admin_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(adminStatsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Overview of your DoorBell platform',
            style: TextStyle(color: Colors.white.withAlpha(120)),
          ),
          const SizedBox(height: 24),
          stats.when(
            data: (s) => Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _StatCard(
                  icon: Icons.people_rounded,
                  label: 'Total Users',
                  value: '${s.totalUsers}',
                  color: const Color(0xFF3498DB),
                ),
                _StatCard(
                  icon: Icons.store_rounded,
                  label: 'Total Shops',
                  value: '${s.totalShops}',
                  color: const Color(0xFF2ECC71),
                ),
                _StatCard(
                  icon: Icons.delivery_dining_rounded,
                  label: 'Total Riders',
                  value: '${s.totalRiders}',
                  color: const Color(0xFFF39C12),
                ),
                _StatCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Orders',
                  value: '${s.totalOrders}',
                  color: const Color(0xFF9B59B6),
                ),
                _StatCard(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Total Revenue',
                  value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                      .format(s.revenue),
                  color: const Color(0xFF1ABC9C),
                  wide: true,
                ),
                _StatCard(
                  icon: Icons.warning_rounded,
                  label: 'Pending Issues',
                  value: '${s.pendingIssues}',
                  color: const Color(0xFFE74C3C),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(adminStatsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickAction(
                icon: Icons.send_rounded,
                label: 'Broadcast Notification',
                onTap: () => _showBroadcastDialog(context, ref),
              ),
              _QuickAction(
                icon: Icons.refresh_rounded,
                label: 'Refresh Stats',
                onTap: () => ref.invalidate(adminStatsProvider),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
              await ref.read(adminActionsProvider).broadcastNotification(
                    title: titleCtrl.text,
                    body: bodyCtrl.text,
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Send to All'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 320 : 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withAlpha(120),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF313152)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF34C759)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
