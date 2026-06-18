import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  /// Notifications for a specific user, ordered by creation date.
  /// Uses UID directly (not the full user object) to avoid stream churn.
  Stream<List<NotificationModel>> forUser(String uid) => _notifications
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((s) => s.docs.map(NotificationModel.fromDoc).toList());

  Future<void> markRead(String id) =>
      _notifications.doc(id).update({'isRead': true});

  Future<void> markAllRead(String uid) async {
    final unread = await _notifications
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// All notifications for admin view.
  Stream<List<NotificationModel>> allNotifications({int limit = 100}) =>
      _notifications
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map(NotificationModel.fromDoc).toList());

  /// Create a notification.
  Future<void> createNotification(NotificationModel notification) =>
      _notifications.add(notification.toMap());

  /// Delete a notification.
  Future<void> deleteNotification(String id) =>
      _notifications.doc(id).delete();
}
