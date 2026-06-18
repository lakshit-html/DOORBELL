import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/enums.dart';

/// Result returned by a payment gateway.
class PaymentResult {
  const PaymentResult._(this.success, this.paymentId, this.error);
  factory PaymentResult.success(String paymentId) =>
      PaymentResult._(true, paymentId, null);
  factory PaymentResult.failure(String error) =>
      PaymentResult._(false, null, error);

  final bool success;
  final String? paymentId;
  final String? error;
}

/// Abstract payment gateway — implement to add new gateways.
abstract class PaymentGateway {
  Future<PaymentResult> pay({
    required double amount,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
  });

  void dispose() {}
}

/// Razorpay gateway — the only active gateway in DoorBell.
class RazorpayGateway implements PaymentGateway {
  RazorpayGateway() {
    _razorpay = Razorpay();
  }

  late final Razorpay _razorpay;

  @override
  void dispose() => _razorpay.clear();

  @override
  Future<PaymentResult> pay({
    required double amount,
    required String name,
    required String description,
    String? email,
    String? contact,
    String? orderId,
  }) {
    final completer = Completer<PaymentResult>();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      _razorpay.clear();
      completer.complete(PaymentResult.success(r.paymentId ?? ''));
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      _razorpay.clear();
      completer.complete(PaymentResult.failure(r.message ?? 'Payment failed'));
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {});

    _razorpay.open({
      'key': AppConstants.razorpayKey,
      'amount': (amount * 100).round(),
      'name': name,
      'description': description,
      'currency': 'INR',
      if (orderId != null) 'order_id': orderId,
      'prefill': {'contact': contact ?? '', 'email': email ?? ''},
      'theme': {'color': '#34C759'},
    });

    return completer.future;
  }
}

/// Factory — only Razorpay is supported. Other methods (COD, Wallet, UPI,
/// Card) are handled in-app without an external SDK.
class PaymentService {
  static PaymentGateway gatewayFor(PaymentMethod method) {
    if (method == PaymentMethod.razorpay) return RazorpayGateway();
    throw UnsupportedError(
        '${method.name} does not use an external gateway.');
  }
}
