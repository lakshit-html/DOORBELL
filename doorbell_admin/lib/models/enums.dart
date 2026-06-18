/// Domain enums — identical to the customer app for Firestore compatibility.
library;

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

enum PaymentMethod {
  cod,
  upi,
  card,
  wallet,
  razorpay;

  static PaymentMethod fromString(String? v) =>
      PaymentMethod.values.firstWhere(
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
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  refunded;

  static PaymentStatus fromString(String? v) =>
      PaymentStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => PaymentStatus.pending,
      );
}

enum ApprovalStatus {
  active,
  suspended;

  static ApprovalStatus fromString(String? v) =>
      ApprovalStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ApprovalStatus.active,
      );

  String get label => switch (this) {
        ApprovalStatus.active => 'Active',
        ApprovalStatus.suspended => 'Suspended',
      };
}

enum RiderStatus {
  offline,
  online,
  sleep,
  busy,
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
}
