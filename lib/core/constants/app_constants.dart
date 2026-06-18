/// Global, compile-time configuration for the DoorBell app.
class AppConstants {
  const AppConstants._();

  static const String appName = 'DoorBell';
  static const String appTagline = 'Your neighbourhood, delivered.';

  // ---- Secrets (override with --dart-define in CI / release builds) ----
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');
  static const String razorpayKey =
      String.fromEnvironment('RAZORPAY_KEY', defaultValue: 'rzp_test_xxxxxxxx');

  // ---- Hyperlocal: Chopasni, Jodhpur (first launch area) ----
  static const double chopasniLat = 26.3016;
  static const double chopasniLng = 73.0179;
  static const double hyperlocalRadiusKm = 3.0;
  static const double defaultDeliveryRadiusKm = 5.0;

  // ---- Business rules ----
  static const double baseDeliveryFee = 25.0;
  static const double freeDeliveryThreshold = 499.0;
  static const double perKmDeliveryFee = 7.0;
  static const int otpResendSeconds = 30;

  // ---- Low-stock alert threshold ----
  static const int lowStockThreshold = 5;

  // ---- Local storage keys ----
  static const String prefsOnboardingDone = 'onboarding_done';
  static const String prefsSavedAddresses = 'saved_addresses';
  static const String prefsThemeMode = 'theme_mode';
}
