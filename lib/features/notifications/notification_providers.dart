import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/firebase_providers.dart';
import '../../data/models/notification_model.dart';
import '../auth/providers/auth_providers.dart';

/// User notifications — depends on stable UID, NOT the full user profile.
/// This prevents stream recreation and repeated subscriptions when profile
/// fields change.
final notificationsProvider =
    StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).forUser(uid);
});

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsProvider).value ?? const [];
  return list.where((n) => !n.isRead).length;
});
