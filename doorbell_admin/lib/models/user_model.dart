import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class UserModel {
  const UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.profileImage,
    required this.status,
    this.fcmToken,
    this.createdAt,
  });

  final String uid;
  final UserRole role;
  final String name;
  final String email;
  final String? phone;
  final String? profileImage;
  final AccountStatus status;
  final String? fcmToken;
  final DateTime? createdAt;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      role: UserRole.fromString(map['role'] as String?),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String?,
      profileImage: map['profileImage'] as String?,
      status: AccountStatus.fromString(map['status'] as String?),
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromMap(doc.id, doc.data() ?? {});
}
