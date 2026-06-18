import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Outcome of a location request, so the UI can show a specific message and the
/// right call-to-action (enable GPS vs open app settings).
enum LocationStatus { ok, serviceDisabled, denied, deniedForever, error }

class LocationResult {
  const LocationResult(this.status, [this.position]);
  final LocationStatus status;
  final Position? position;

  bool get isOk => status == LocationStatus.ok && position != null;

  String get message => switch (status) {
        LocationStatus.ok => 'Location captured',
        LocationStatus.serviceDisabled =>
          'Location is turned off. Please enable GPS / Location.',
        LocationStatus.denied => 'Location permission was denied.',
        LocationStatus.deniedForever =>
          'Location permission is permanently denied. Enable it in Settings.',
        LocationStatus.error => 'Could not get your location. Please try again.',
      };
}

/// Wraps geolocator + geocoding for current-location detection and reverse
/// geocoding. Handles the full permission + service flow with fallbacks.
class LocationService {
  const LocationService();

  /// Detailed variant: tells the caller *why* it failed.
  Future<LocationResult> requestPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult(LocationStatus.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(LocationStatus.deniedForever);
    }
    if (permission == LocationPermission.denied) {
      return const LocationResult(LocationStatus.denied);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LocationResult(LocationStatus.ok, position);
    } catch (_) {
      // High-accuracy fix can time out indoors/emulators — fall back to the
      // last known location so the user isn't blocked.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return LocationResult(LocationStatus.ok, last);
      return const LocationResult(LocationStatus.error);
    }
  }

  /// Opens the OS location settings (when GPS is off).
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  /// Opens this app's settings page (when permission is permanently denied).
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> ensurePermission() async {
    final result = await requestPosition();
    return result.status != LocationStatus.deniedForever;
  }

  /// Backwards-compatible helper used by providers; returns null on any failure.
  Future<Position?> getCurrentPosition() async =>
      (await requestPosition()).position;

  /// Streams position updates — used for rider live tracking.
  Stream<Position> positionStream({int distanceFilterMeters = 20}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    );
  }

  Future<String?> addressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final p = placemarks.first;
      return [p.name, p.subLocality, p.locality, p.postalCode]
          .where((e) => e != null && e.isNotEmpty)
          .join(', ');
    } catch (_) {
      return null;
    }
  }
}
