import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/providers/firebase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/enums.dart';
import '../../data/models/order_model.dart';
import '../orders/orders_providers.dart';

/// Live order tracking: a Google Map with the shop, the delivery address, and
/// the rider's live position, plus a status timeline.
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: order.when(
        data: (o) {
          if (o == null) {
            return const EmptyState(
                icon: Icons.receipt_long_outlined, title: 'Order not found');
          }
          return Column(
            children: [
              Expanded(flex: 3, child: _OrderMap(order: o, ref: ref)),
              Expanded(flex: 2, child: _StatusTimeline(order: o)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => EmptyState(icon: Icons.error_outline, title: '$e'),
      ),
    );
  }
}

class _OrderMap extends StatelessWidget {
  const _OrderMap({required this.order, required this.ref});
  final OrderModel order;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final dest = LatLng(
        order.deliveryAddress.latitude, order.deliveryAddress.longitude);

    // Live rider location (if a rider is assigned).
    final riderAsync = order.riderId == null
        ? const AsyncValue.data(null)
        : ref.watch(_riderLocationProvider(order.riderId!));

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('destination'),
        position: dest,
        infoWindow: const InfoWindow(title: 'Delivery Address'),
      ),
    };
    final rider = riderAsync.value;
    if (rider != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(rider.$1, rider.$2),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Your Rider'),
      ));
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: dest, zoom: 14),
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

/// Streams the assigned rider's live coordinates as a (lat, lng) record.
final _riderLocationProvider = StreamProvider.autoDispose
    .family<(double, double)?, String>((ref, riderId) {
  return ref.watch(riderRepositoryProvider).riderStream(riderId).map((r) {
    if (r?.currentLat == null || r?.currentLng == null) return null;
    return (r!.currentLat!, r.currentLng!);
  });
});

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.order});
  final OrderModel order;

  static const _flow = [
    OrderStatus.placed,
    OrderStatus.accepted,
    OrderStatus.preparing,
    OrderStatus.riderAssigned,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _flow.indexOf(order.orderStatus);
    final cancelled = order.orderStatus == OrderStatus.cancelled ||
        order.orderStatus == OrderStatus.rejected;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
      ),
      padding: const EdgeInsets.all(20),
      child: cancelled
          ? Center(
              child: Text(order.orderStatus.label,
                  style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            )
          : ListView(
              children: [
                Text('Order #${order.orderId.substring(0, 6).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                ..._flow.asMap().entries.map((e) {
                  final done = e.key <= currentIndex;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.primary
                                  : AppColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: done
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          if (e.key != _flow.length - 1)
                            Container(
                              width: 2,
                              height: 28,
                              color: done
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(e.value.label,
                            style: TextStyle(
                                fontWeight:
                                    done ? FontWeight.w700 : FontWeight.w400,
                                color: done
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary)),
                      ),
                    ],
                  );
                }),
              ],
            ),
    );
  }
}
