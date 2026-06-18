import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'general',
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  final String notificationId;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      NotificationModel(
        notificationId: id,
        userId: map['userId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? 'general',
        data: Map<String, dynamic>.from(map['data'] as Map? ?? const {}),
        isRead: map['isRead'] as bool? ?? false,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory NotificationModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      NotificationModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'isRead': isRead,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
