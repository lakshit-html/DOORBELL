import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';

/// The user's current location + reverse-geocoded label.
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  final double latitude;
  final double longitude;
  final String? address;
}

/// Detects the device location once on build; call [refresh] to re-detect.
class LocationController extends AsyncNotifier<UserLocation?> {
  @override
  Future<UserLocation?> build() => _detect();

  Future<UserLocation?> _detect() async {
    final service = ref.read(locationServiceProvider);
    final pos = await service.getCurrentPosition();
    if (pos == null) return null;
    final address =
        await service.addressFromCoordinates(pos.latitude, pos.longitude);
    return UserLocation(
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: address,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_detect);
  }

  /// Lets the user pick a location manually (e.g. via the map place picker).
  void setManual(double lat, double lng, String? address) {
    state = AsyncData(
        UserLocation(latitude: lat, longitude: lng, address: address));
  }
}

final locationProvider =
    AsyncNotifierProvider<LocationController, UserLocation?>(
        LocationController.new);
