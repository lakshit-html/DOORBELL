import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/enums.dart';
import '../../auth/providers/auth_providers.dart';
import '../../orders/screens/orders_screen.dart';
import '../rider_providers.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  StreamSubscription<Position>? _locationSub;

  void _setStatus(RiderStatus status, String riderId) {
    ref.read(riderRepositoryProvider).setStatus(riderId, status);

    // Start/stop GPS based on new status.
    if (status.trackLocation && _locationSub == null) {
      _locationSub = ref
          .read(locationServiceProvider)
          .positionStream()
          .listen((pos) {
        ref
            .read(riderRepositoryProvider)
            .updateLocation(riderId, pos.latitude, pos.longitude);
      });
    } else if (!status.trackLocation) {
      _locationSub?.cancel();
      _locationSub = null;
    }
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = ref.watch(myRiderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: rider.when(
        data: (r) {
          if (r == null) {
            return EmptyState(
              icon: Icons.delivery_dining_outlined,
              title: 'Complete your rider profile',
              subtitle:
                  'Upload your documents to start accepting deliveries.',
              actionLabel: 'Register as Rider',
              onAction: () => context.push(AppRoutes.riderRegister),
            );
          }
          if (r.approvalStatus != ApprovalStatus.approved) {
            return EmptyState(
              icon: r.approvalStatus == ApprovalStatus.rejected
                  ? Icons.cancel_outlined
                  : Icons.hourglass_top,
              title: r.approvalStatus == ApprovalStatus.rejected
                  ? 'Application rejected'
                  : 'Verification in progress',
              subtitle: r.approvalStatus == ApprovalStatus.rejected
                  ? 'Please contact support for details.'
                  : 'Our team is reviewing your documents. Usually takes 24 h.',
            );
          }
          return _ApprovedRiderView(
            rider: r,
            onSetStatus: _setStatus,
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, __) =>
            EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}

// ── Approved rider view ───────────────────────────────────────────────────

class _ApprovedRiderView extends ConsumerWidget {
  const _ApprovedRiderView(
      {required this.rider, required this.onSetStatus});

  final dynamic rider;
  final void Function(RiderStatus status, String riderId) onSetStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(availableDeliveriesProvider);
    final mine = ref.watch(myDeliveriesProvider);
    final status = rider.status as RiderStatus;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Earnings card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Earnings',
                      style: TextStyle(color: Colors.white)),
                  _StatusBadge(status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Formatters.currency(rider.earnings as double),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Row(children: [
                _miniStat('Deliveries', '${rider.totalDeliveries}'),
                const SizedBox(width: 24),
                _miniStat(
                    'Rating',
                    (rider.rating as double).toStringAsFixed(1)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Status selector ────────────────────────────────────────────
        _StatusSelector(
          current: status,
          riderId: rider.riderId as String,
          onChanged: onSetStatus,
        ),
        const SizedBox(height: 20),

        // ── Active deliveries ──────────────────────────────────────────
        Text('Active Deliveries',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        mine.when(
          data: (list) {
            final active =
                list.where((o) => !o.orderStatus.isTerminal).toList();
            if (active.isEmpty) {
              return const Text('No active deliveries.',
                  style: TextStyle(color: AppColors.textSecondary));
            }
            return Column(
                children:
                    active.map((o) => _DeliveryCard(order: o)).toList());
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, __) => Text('$e'),
        ),
        const SizedBox(height: 20),

        // ── Available requests (only shown when online) ────────────────
        Row(children: [
          Text('Available Requests',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          if (!status.canReceiveOrders)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Go Online to see requests',
                  style: TextStyle(
                      fontSize: 11,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 8),
        if (status.canReceiveOrders)
          available.when(
            data: (list) => list.isEmpty
                ? const Text('No delivery requests right now.',
                    style: TextStyle(color: AppColors.textSecondary))
                : Column(
                    children: list
                        .map((o) => _DeliveryCard(
                              order: o,
                              showAccept: true,
                              riderStatus: status,
                            ))
                        .toList()),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('$e'),
          )
        else
          const Text('You are not receiving requests right now.',
              style: TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _miniStat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9))),
        ],
      );
}

// ── Status badge ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final RiderStatus status;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(status.label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ]),
      );
}

// ── Status selector ───────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  const _StatusSelector({
    required this.current,
    required this.riderId,
    required this.onChanged,
  });
  final RiderStatus current;
  final String riderId;
  final void Function(RiderStatus, String) onChanged;

  static const _statuses = [
    RiderStatus.online,
    RiderStatus.sleep,
    RiderStatus.busy,
    RiderStatus.offline,
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Status',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
              'Only "Online" riders receive delivery requests.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((s) {
                final selected = s == current;
                return GestureDetector(
                  onTap: () => onChanged(s, riderId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? s.color.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? s.color : AppColors.border,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(s.label,
                          style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected ? s.color : null)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
}

// ── Delivery card ─────────────────────────────────────────────────────────

class _DeliveryCard extends ConsumerWidget {
  const _DeliveryCard({
    required this.order,
    this.showAccept = false,
    this.riderStatus,
  });

  final dynamic order;
  final bool showAccept;
  final RiderStatus? riderStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(orderRepositoryProvider);
    final user = ref.read(currentUserProvider).value;
    final status = order.orderStatus as OrderStatus;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID + status
            Row(children: [
              Expanded(
                child: Text(
                    '#${(order.orderId as String).substring(0, 6).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              OrderStatusChip(status: status),
            ]),
            const SizedBox(height: 8),

            // Delivery address
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(
                      order.deliveryAddress.formatted as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),

            // Payout
            Text(
              'Payout: ${Formatters.currency(order.deliveryFee as double)}',
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w700),
            ),

            // Scheduled slot if any
            if (order.scheduledSlot != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.schedule,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(order.scheduledSlot!.label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ]),
            ],
            const SizedBox(height: 10),

            // Actions
            if (showAccept)
              _acceptButton(context, repo, user)
            else
              _activeActions(context, repo, status),
          ],
        ),
      ),
    );
  }

  Widget _acceptButton(
      BuildContext context, dynamic repo, dynamic user) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Accept Delivery'),
        onPressed: user == null
            ? null
            : () async {
                final won = await repo.assignRider(
                    order.orderId as String, user.uid as String);
                if (context.mounted) {
                  if (won) {
                    AppSnackbar.success(context,
                        'Delivery accepted! Head to the shop now.');
                  } else {
                    AppSnackbar.error(context,
                        'Another rider accepted this order first.');
                  }
                }
              },
      ),
    );
  }

  Widget _activeActions(
      BuildContext context, dynamic repo, OrderStatus status) {
    switch (status) {
      case OrderStatus.riderAssigned:
        return FilledButton(
          onPressed: () =>
              repo.updateStatus(order.orderId, OrderStatus.pickedUp, riderId: order.riderId as String?),
          child: const Text('Mark Picked Up'),
        );
      case OrderStatus.pickedUp:
        return FilledButton(
          onPressed: () => repo.updateStatus(
              order.orderId, OrderStatus.outForDelivery, riderId: order.riderId as String?),
          child: const Text('Start Delivery'),
        );
      case OrderStatus.outForDelivery:
        return Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map_outlined, size: 16),
              label: const Text('Navigate'),
              onPressed: () {
                final lat = order.deliveryAddress.latitude;
                final lng = order.deliveryAddress.longitude;
                launchUrl(
                  Uri.parse(
                      'https://www.google.com/maps/dir/?api=1'
                      '&destination=$lat,$lng'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('Delivered'),
              onPressed: () =>
                  repo.updateStatus(order.orderId, OrderStatus.delivered, riderId: order.riderId as String?),
            ),
          ),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }
}
