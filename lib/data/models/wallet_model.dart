import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  credit,
  debit;

  static TransactionType fromString(String? v) =>
      TransactionType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => TransactionType.credit,
      );
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.orderId,
    this.createdAt,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String description;
  final String? orderId;
  final DateTime? createdAt;

  factory WalletTransaction.fromMap(String id, Map<String, dynamic> map) =>
      WalletTransaction(
        id: id,
        type: TransactionType.fromString(map['type'] as String?),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        description: map['description'] as String? ?? '',
        orderId: map['orderId'] as String?,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'amount': amount,
        'description': description,
        'orderId': orderId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };
}

class WalletModel {
  const WalletModel({
    required this.userId,
    this.balance = 0,
    this.transactions = const [],
  });

  final String userId;
  final double balance;
  final List<WalletTransaction> transactions;

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) =>
      WalletModel(
        userId: id,
        balance: (map['balance'] as num?)?.toDouble() ?? 0,
      );
}
