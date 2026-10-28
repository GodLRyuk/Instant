import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayResult {
  const RazorpayResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

/// Opens Razorpay checkout for an order created by the server.
/// Returns null when the customer cancels or the payment fails.
class RazorpayCheckout {
  static Future<RazorpayResult?> pay({
    required String keyId,
    required String orderId,
    required int amountPaise,
    required String name,
    String description = '',
    String? contact,
    String? email,
  }) {
    final completer = Completer<RazorpayResult?>();
    final razorpay = Razorpay();

    void finish(RazorpayResult? result) {
      if (completer.isCompleted) return;
      razorpay.clear();
      completer.complete(result);
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse r) {
      finish(RazorpayResult(
        paymentId: r.paymentId ?? '',
        orderId: r.orderId ?? orderId,
        signature: r.signature ?? '',
      ));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) => finish(null));
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse r) {});

    razorpay.open({
      'key': keyId,
      'amount': amountPaise,
      'order_id': orderId,
      'name': name,
      'description': description,
      'prefill': {
        if (contact != null) 'contact': contact,
        if (email != null) 'email': email,
      },
      'theme': {'color': '#2E7D32'},
    });
    return completer.future;
  }
}
