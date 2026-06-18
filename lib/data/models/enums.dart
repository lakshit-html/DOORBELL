import 'package:flutter/material.dart';

// Domain enums with safe string (de)serialisation for Firestore.

enum UserRole {
  customer,
  shopOwner,
  rider,
  admin;

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
    (e) => e.name == value,
    orElse: () => UserRole.customer,
  );

  String get label => switch (this) {
    UserRole.customer => 'Customer',
    UserRole.shopOwner => 'Shop Owner',
    UserRole.rider => 'Delivery Rider',
    UserRole.admin => 'Admin',
  };
}

enum AccountStatus {
  active,
  suspended,
  pending;

  static AccountStatus fromString(String? v) => AccountStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => AccountStatus.active,
  );
}

enum OrderStatus {
  placed,
  accepted,
  rejected,
  preparing,
  readyForPickup,
  riderAssigned,
  pickedUp,
  outForDelivery,
  delivered,
  cancelled;

  static OrderStatus fromString(String? v) => OrderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => OrderStatus.placed,
  );

  String get label => switch (this) {
    OrderStatus.placed => 'Order Placed',
    OrderStatus.accepted => 'Accepted',
    OrderStatus.rejected => 'Rejected',
    OrderStatus.preparing => 'Preparing',
    OrderStatus.readyForPickup => 'Ready for Pickup',
    OrderStatus.riderAssigned => 'Rider Assigned',
    OrderStatus.pickedUp => 'Picked Up',
    OrderStatus.outForDelivery => 'Out for Delivery',
    OrderStatus.delivered => 'Delivered',
    OrderStatus.cancelled => 'Cancelled',
  };

  bool get isTerminal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.rejected;
}

/// Payment methods supported by DoorBell.
/// Only COD, Wallet, UPI, Card, and Razorpay are active.
enum PaymentMethod {
  cod,
  upi,
  card,
  wallet,
  razorpay;

  static PaymentMethod fromString(String? v) => PaymentMethod.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PaymentMethod.cod,
  );

  String get label => switch (this) {
    PaymentMethod.cod => 'Cash on Delivery',
    PaymentMethod.upi => 'UPI',
    PaymentMethod.card => 'Card',
    PaymentMethod.wallet => 'DoorBell Wallet',
    PaymentMethod.razorpay => 'Razorpay',
  };

  /// Whether an external gateway SDK handles this method.
  bool get requiresGateway => this == PaymentMethod.razorpay;
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String? v) => PaymentStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PaymentStatus.pending,
  );
}

enum VehicleType {
  bike,
  scooter,
  bicycle,
  car;

  static VehicleType fromString(String? v) => VehicleType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => VehicleType.bike,
  );
}

enum RiderStatus {
  /// Not working — receives NO delivery requests.
  offline,

  /// Active and ready to accept orders.
  online,

  /// Temporarily on break — no new requests.
  sleep,

  /// Occupied — no new requests.
  busy,

  /// Currently on a delivery.
  delivering;

  static RiderStatus fromString(String? v) => RiderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => RiderStatus.offline,
  );

  String get label => switch (this) {
    RiderStatus.offline => 'Offline',
    RiderStatus.online => 'Online',
    RiderStatus.sleep => 'On Break',
    RiderStatus.busy => 'Busy',
    RiderStatus.delivering => 'Delivering',
  };

  bool get canReceiveOrders => this == RiderStatus.online;

  bool get trackLocation =>
      this == RiderStatus.online || this == RiderStatus.delivering;

  Color get color => switch (this) {
    RiderStatus.offline => const Color(0xFF9CA3AF),
    RiderStatus.online => const Color(0xFF22C55E),
    RiderStatus.sleep => const Color(0xFFF59E0B),
    RiderStatus.busy => const Color(0xFFEF4444),
    RiderStatus.delivering => const Color(0xFF3B82F6),
  };
}

enum ApprovalStatus {
  pending,
  approved,
  rejected,
  active,
  suspended;

  String get displayName {
    switch (this) {
      case ApprovalStatus.pending:
        return 'Pending';
      case ApprovalStatus.approved:
        return 'Approved';
      case ApprovalStatus.rejected:
        return 'Rejected';
      case ApprovalStatus.active:
        return 'Active';
      case ApprovalStatus.suspended:
        return 'Suspended';
    }
  }

  static ApprovalStatus fromString(String value) {
    return ApprovalStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ApprovalStatus.pending,
    );
  }
}

/// Scheduled delivery time slots (30-minute windows).
enum DeliverySlot {
  asap,
  slot10to1030,
  slot1030to11,
  slot11to1130,
  slot1130to12,
  slot12to1230,
  slot1230to13,
  slot13to1330,
  slot1330to14,
  slot14to1430,
  slot1430to15,
  slot15to1530,
  slot1530to16,
  slot16to1630,
  slot1630to17,
  slot17to1730,
  slot1730to18,
  slot18to1830,
  slot1830to19,
  slot19to1930,
  slot1930to20,
  slot20to2030,
  slot2030to21;

  static DeliverySlot fromString(String? v) => DeliverySlot.values.firstWhere(
    (e) => e.name == v,
    orElse: () => DeliverySlot.asap,
  );

  String get label => switch (this) {
    DeliverySlot.asap => 'As soon as possible',
    DeliverySlot.slot10to1030 => '10:00 AM – 10:30 AM',
    DeliverySlot.slot1030to11 => '10:30 AM – 11:00 AM',
    DeliverySlot.slot11to1130 => '11:00 AM – 11:30 AM',
    DeliverySlot.slot1130to12 => '11:30 AM – 12:00 PM',
    DeliverySlot.slot12to1230 => '12:00 PM – 12:30 PM',
    DeliverySlot.slot1230to13 => '12:30 PM – 1:00 PM',
    DeliverySlot.slot13to1330 => '1:00 PM – 1:30 PM',
    DeliverySlot.slot1330to14 => '1:30 PM – 2:00 PM',
    DeliverySlot.slot14to1430 => '2:00 PM – 2:30 PM',
    DeliverySlot.slot1430to15 => '2:30 PM – 3:00 PM',
    DeliverySlot.slot15to1530 => '3:00 PM – 3:30 PM',
    DeliverySlot.slot1530to16 => '3:30 PM – 4:00 PM',
    DeliverySlot.slot16to1630 => '4:00 PM – 4:30 PM',
    DeliverySlot.slot1630to17 => '4:30 PM – 5:00 PM',
    DeliverySlot.slot17to1730 => '5:00 PM – 5:30 PM',
    DeliverySlot.slot1730to18 => '5:30 PM – 6:00 PM',
    DeliverySlot.slot18to1830 => '6:00 PM – 6:30 PM',
    DeliverySlot.slot1830to19 => '6:30 PM – 7:00 PM',
    DeliverySlot.slot19to1930 => '7:00 PM – 7:30 PM',
    DeliverySlot.slot1930to20 => '7:30 PM – 8:00 PM',
    DeliverySlot.slot20to2030 => '8:00 PM – 8:30 PM',
    DeliverySlot.slot2030to21 => '8:30 PM – 9:00 PM',
  };
}

/// E-Mitra service types.
enum EMitraServiceType {
  aadharPrint,
  panPrint,
  incomeCertificate,
  casteCertificate,
  domicileCertificate,
  birthCertificate,
  marriageCertificate,
  electricityBill,
  waterBill,
  customPrint;

  static EMitraServiceType fromString(String? v) =>
      EMitraServiceType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => EMitraServiceType.customPrint,
      );

  String get label => switch (this) {
    EMitraServiceType.aadharPrint => 'Aadhaar Print',
    EMitraServiceType.panPrint => 'PAN Card Print',
    EMitraServiceType.incomeCertificate => 'Income Certificate',
    EMitraServiceType.casteCertificate => 'Caste Certificate',
    EMitraServiceType.domicileCertificate => 'Domicile Certificate',
    EMitraServiceType.birthCertificate => 'Birth Certificate',
    EMitraServiceType.marriageCertificate => 'Marriage Certificate',
    EMitraServiceType.electricityBill => 'Electricity Bill',
    EMitraServiceType.waterBill => 'Water Bill',
    EMitraServiceType.customPrint => 'Custom Print Job',
  };
}
