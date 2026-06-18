import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus {
  open,
  inProgress,
  resolved,
  closed;

  static TicketStatus fromString(String? v) => TicketStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => TicketStatus.open,
      );
}

class SupportTicketModel {
  const SupportTicketModel({
    required this.ticketId,
    required this.userId,
    required this.subject,
    required this.message,
    this.status = TicketStatus.open,
    this.createdAt,
  });

  final String ticketId;
  final String userId;
  final String subject;
  final String message;
  final TicketStatus status;
  final DateTime? createdAt;

  factory SupportTicketModel.fromMap(String id, Map<String, dynamic> map) =>
      SupportTicketModel(
        ticketId: id,
        userId: map['userId'] as String? ?? '',
        subject: map['subject'] as String? ?? '',
        message: map['message'] as String? ?? '',
        status: TicketStatus.fromString(map['status'] as String?),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  factory SupportTicketModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      SupportTicketModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'subject': subject,
        'message': message,
        'status': status.name,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}
