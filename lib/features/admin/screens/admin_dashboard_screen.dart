import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_network_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/enums.dart';
import '../../../data/models/rider_model.dart';
import '../../../data/models/shop_model.dart';
import '../../auth/providers/auth_providers.dart';
import 'package:doorbell/features/admin/admin_providers.dart'
    as admin_providers;

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingShops =
        ref.watch(admin_providers.pendingShopsProvider).value ?? [];
    final pendingRiders =
        ref.watch(admin_providers.pendingRidersProvider).value ?? [];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Console'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Overview'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Shops'),
                    if (pendingShops.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _Badge(pendingShops.length),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Riders'),
                    if (pendingRiders.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _Badge(pendingRiders.length),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_OverviewTab(), _ShopsApprovalTab(), _RidersApprovalTab()],
        ),
      ),
    );
  }
}

// ── Badge ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge(this.count);
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

// ── Overview ─────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(admin_providers.adminStatsProvider);
    final pendingShops =
        ref.watch(admin_providers.pendingShopsProvider).value?.length ?? 0;
    final pendingRiders =
        ref.watch(admin_providers.pendingRidersProvider).value?.length ?? 0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(admin_providers.adminStatsProvider),
      child: stats.when(
        data: (s) => GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _StatCard(
              'Total Users',
              '${s.totalUsers}',
              Icons.people_outline,
              AppColors.info,
            ),
            _StatCard(
              'Active Shops',
              '${s.totalShops}',
              Icons.storefront_outlined,
              AppColors.primary,
            ),
            _StatCard(
              'Active Riders',
              '${s.totalRiders}',
              Icons.delivery_dining_outlined,
              AppColors.warning,
            ),
            _StatCard(
              'Paid Orders',
              '${s.totalOrders}',
              Icons.receipt_long_outlined,
              AppColors.accent,
            ),
            _StatCard(
              'Revenue',
              Formatters.currency(s.revenue),
              Icons.currency_rupee,
              AppColors.success,
            ),
            _StatCard(
              'Pending Reviews',
              '${pendingShops + pendingRiders}',
              Icons.pending_actions,
              AppColors.error,
              highlight: (pendingShops + pendingRiders) > 0,
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
    this.title,
    this.value,
    this.icon,
    this.color, {
    this.highlight = false,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: highlight
          ? AppColors.error.withValues(alpha: 0.07)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight
            ? AppColors.error.withValues(alpha: 0.4)
            : AppColors.border,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: highlight ? AppColors.error : null,
          ),
        ),
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

// ── Shops Approval ───────────────────────────────────────────────────────────

class _ShopsApprovalTab extends ConsumerWidget {
  const _ShopsApprovalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(admin_providers.pendingShopsProvider);
    final approved = ref.watch(admin_providers.approvedShopsProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved / Rejected'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _shopList(context, ref, pending, showActions: true),
                _shopList(context, ref, approved, showActions: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ShopModel>> shops, {
    required bool showActions,
  }) {
    return shops.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'Nothing here',
              subtitle: 'All caught up!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) =>
                  _ShopCard(shop: list[i], showActions: showActions),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
    );
  }
}

class _ShopCard extends ConsumerWidget {
  const _ShopCard({required this.shop, required this.showActions});
  final ShopModel shop;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(shopRepositoryProvider);
    final statusColor = switch (shop.approvalStatus) {
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.rejected => AppColors.error,
      _ => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (shop.coverImage != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AppNetworkImage(
                url: shop.coverImage,
                width: double.infinity,
                height: 130,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.shopName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        shop.approvalStatus.displayName.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Address
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop.address,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Categories
                if (shop.categories.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: shop.categories
                        .map(
                          (c) => Chip(
                            label: Text(
                              c,
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),

                if (shop.gstNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'GST: ${shop.gstNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Registered on
                if (shop.createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Applied: ${Formatters.date(shop.createdAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Action buttons (only on pending)
                if (showActions) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: AppColors.error,
                            size: 18,
                          ),
                          label: const Text(
                            'Reject',
                            style: TextStyle(color: AppColors.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                          ),
                          onPressed: () => _confirmReject(context, ref, repo),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: const Text('Approve'),
                          onPressed: () => _confirmApprove(context, ref, repo),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Shop'),
        content: Text(
          'Approve "${shop.shopName}"?\n\nThey will be able to receive orders immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.setApproval(shop.shopId, approved: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${shop.shopName} approved ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmReject(
    BuildContext context,
    WidgetRef ref,
    dynamic repo,
  ) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject "${shop.shopName}"?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Incomplete documents',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.setApproval(
        shop.shopId,
        approved: false,
        reason: reasonController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    reasonController.dispose();
  }
}

// ── Riders Approval ──────────────────────────────────────────────────────────

class _RidersApprovalTab extends ConsumerWidget {
  const _RidersApprovalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(admin_providers.pendingRidersProvider);
    final reviewed = ref.watch(admin_providers.reviewedRidersProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved / Rejected'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _riderList(context, ref, pending, showActions: true),
                _riderList(context, ref, reviewed, showActions: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riderList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RiderModel>> riders, {
    required bool showActions,
  }) {
    return riders.when(
      data: (list) => list.isEmpty
          ? const EmptyState(
              icon: Icons.delivery_dining_outlined,
              title: 'Nothing here',
              subtitle: 'All caught up!',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (_, i) =>
                  _RiderCard(rider: list[i], showActions: showActions),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
    );
  }
}

class _RiderCard extends ConsumerWidget {
  const _RiderCard({required this.rider, required this.showActions});
  final RiderModel rider;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(riderRepositoryProvider);
    final statusColor = switch (rider.approvalStatus) {
      ApprovalStatus.approved => AppColors.success,
      ApprovalStatus.rejected => AppColors.error,
      _ => AppColors.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    rider.name.isNotEmpty ? rider.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rider.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        rider.phone,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    rider.approvalStatus.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Vehicle details
            _detail(
              Icons.two_wheeler_outlined,
              '${rider.vehicleType.name.toUpperCase()} — ${rider.vehicleNumber}',
            ),
            if (rider.licenseNumber != null)
              _detail(Icons.badge_outlined, 'License: ${rider.licenseNumber}'),
            if (rider.createdAt != null)
              _detail(
                Icons.calendar_today_outlined,
                'Applied: ${Formatters.date(rider.createdAt!)}',
              ),

            // KYC document thumbnails
            if (_hasDocs) ...[
              const SizedBox(height: 10),
              Text(
                'KYC Documents',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (rider.selfieImage != null)
                      _DocThumb(url: rider.selfieImage!, label: 'Selfie'),
                    if (rider.aadhaarImage != null)
                      _DocThumb(url: rider.aadhaarImage!, label: 'Aadhaar'),
                    if (rider.licenseImage != null)
                      _DocThumb(url: rider.licenseImage!, label: 'License'),
                    if (rider.rcImage != null)
                      _DocThumb(url: rider.rcImage!, label: 'RC'),
                  ],
                ),
              ),
            ],

            // Action buttons
            if (showActions) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        color: AppColors.error,
                        size: 18,
                      ),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: AppColors.error),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                      ),
                      onPressed: () => _confirmReject(context, repo),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Approve'),
                      onPressed: () => _confirmApprove(context, repo),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _hasDocs =>
      rider.selfieImage != null ||
      rider.aadhaarImage != null ||
      rider.licenseImage != null ||
      rider.rcImage != null;

  Widget _detail(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmApprove(BuildContext context, dynamic repo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Rider'),
        content: Text(
          'Approve ${rider.name}?\n\nThey will be able to go online and accept deliveries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.setApproval(rider.riderId, ApprovalStatus.approved);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${rider.name} approved ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmReject(BuildContext context, dynamic repo) async {
    final reasonController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Rider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject ${rider.name}\'s application?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Documents not clear',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await repo.setApproval(
        rider.riderId,
        ApprovalStatus.rejected,
        reason: reasonController.text.trim(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    reasonController.dispose();
  }
}

class _DocThumb extends StatelessWidget {
  const _DocThumb({required this.url, required this.label});
  final String url;
  final String label;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => _viewFull(context),
    child: Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AppNetworkImage(url: url, width: 80, height: 60),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  void _viewFull(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(label),
              leading: CloseButton(onPressed: () => Navigator.pop(ctx)),
              automaticallyImplyLeading: false,
            ),
            AppNetworkImage(url: url, width: double.infinity, height: 300),
          ],
        ),
      ),
    );
  }
}
