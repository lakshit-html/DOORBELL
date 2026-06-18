import 'dart:math' as math;

/// Geospatial helpers that don't require a plugin (pure Dart) so they can be
/// unit-tested and used on any platform.
class GeoUtils {
  const GeoUtils._();

  static const double earthRadiusKm = 6371.0;

  /// Haversine distance in kilometres between two lat/lng points.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180);
}
