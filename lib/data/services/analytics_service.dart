import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin wrapper over Firebase Analytics for typed, app-specific events.
class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logScreen(String screen) =>
      _analytics.logScreenView(screenName: screen);

  Future<void> logAddToCart(String productId, double value) =>
      _analytics.logAddToCart(currency: 'INR', value: value, items: [
        AnalyticsEventItem(itemId: productId),
      ]);

  Future<void> logPurchase(double value, String orderId) =>
      _analytics.logPurchase(
          currency: 'INR', value: value, transactionId: orderId);

  Future<void> setUserRole(String role) =>
      _analytics.setUserProperty(name: 'role', value: role);
}
