import 'dart:developer' as dev;

import 'package:firebase_messaging/firebase_messaging.dart';

/// Firebase Cloud Messaging setup: permissions, token, and message handlers.
/// Cloud Functions send the actual pushes (see /functions).
class NotificationService {
  NotificationService(this._messaging);

  final FirebaseMessaging _messaging;

  Future<void> init({
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpened,
  }) async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((message) {
      dev.log('FCM foreground: ${message.notification?.title}',
          name: 'NotificationService');
      onForegroundMessage?.call(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onMessageOpened?.call(message);
    });
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Topic subscriptions let Cloud Functions broadcast by role/shop.
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);
}
