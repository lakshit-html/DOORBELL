import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/rider_model.dart';
import '../models/enums.dart';
import '../providers/admin_providers.dart';

class RidersScreen extends ConsumerWidget {
  const RidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridersAsync = ref.watch(allRidersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rider Management',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Expanded(
            child: ridersAsync.when(
              data: (riders) => riders.isEmpty
                  ? const Center(child: Text('No riders found'))
                  : ListView.builder(
                      itemCount: riders.length,
                      itemBuilder: (_, i) => _RiderTile(rider: riders[i]),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderTile extends ConsumerWidget {
  const _RiderTile({required this.rider});
  final RiderModel rider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = rider.approvalStatus == ApprovalStatus.active;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withAlpha(30),
          child: const Icon(Icons.delivery_dining, color: Colors.orange),
        ),
        title: Text(rider.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${rider.phone} • ${rider.totalDeliveries} deliveries • ${rider.status.label}',
          style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withAlpha(30) : Colors.red.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rider.approvalStatus.label,
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (isActive)
              IconButton(
                icon: const Icon(Icons.block, color: Colors.orange, size: 20),
                tooltip: 'Suspend',
                onPressed: () => ref.read(adminActionsProvider).suspendRider(rider.riderId),
              )
            else
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                tooltip: 'Reactivate',
                onPressed: () => ref.read(adminActionsProvider).reactivateRider(rider.riderId),
              ),
          ],
        ),
      ),
    );
  }
}
