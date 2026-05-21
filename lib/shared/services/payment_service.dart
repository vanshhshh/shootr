import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'backend_api_service.dart';

enum PaymentGateway { razorpay, stripe }

class PaymentRequest {
  const PaymentRequest({
    required this.amount,
    required this.currency,
    required this.description,
    required this.city,
    required this.bookingId,
    this.customerName,
    this.customerEmail,
    this.customerContact,
  });

  final double amount;
  final String currency;
  final String description;
  final String city;
  final String bookingId;
  final String? customerName;
  final String? customerEmail;
  final String? customerContact;
}

class PaymentCheckoutResult {
  const PaymentCheckoutResult({
    required this.success,
    this.orderId,
    this.paymentId,
    this.message,
  });

  final bool success;
  final String? orderId;
  final String? paymentId;
  final String? message;
}

class PaymentService {
  PaymentService({
    FirebaseFunctions? functions,
    Razorpay? razorpay,
    BackendApiService? backend,
  }) : _razorpay = razorpay ?? Razorpay(),
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'asia-south1'),
       _backend = backend ?? BackendApiService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  final Razorpay _razorpay;
  final FirebaseFunctions _functions;
  final BackendApiService _backend;
  Completer<PaymentCheckoutResult>? _checkoutCompleter;
  String? _pendingBookingId;

  PaymentGateway gatewayFor(String city) {
    if (city == 'Dubai' ||
        city == 'Abu Dhabi' ||
        city == 'New York' ||
        city == 'Los Angeles') {
      return PaymentGateway.stripe;
    }
    return PaymentGateway.razorpay;
  }

  /// Prepares native SDKs that need client-side configuration.
  Future<void> initialize() async {
    const stripePublishableKey = String.fromEnvironment(
      'STRIPE_PUBLISHABLE_KEY',
    );
    if (stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = stripePublishableKey;
      await Stripe.instance.applySettings();
    }
  }

  /// Opens the appropriate checkout flow for the selected market.
  Future<PaymentCheckoutResult> beginCheckout(PaymentRequest request) async {
    switch (gatewayFor(request.city)) {
      case PaymentGateway.razorpay:
        return _beginRazorpayCheckout(request);
      case PaymentGateway.stripe:
        return const PaymentCheckoutResult(
          success: false,
          message: 'Stripe checkout is not configured yet.',
        );
    }
  }

  Future<PaymentCheckoutResult> _beginRazorpayCheckout(
    PaymentRequest request,
  ) async {
    if (_checkoutCompleter != null && !_checkoutCompleter!.isCompleted) {
      return const PaymentCheckoutResult(
        success: false,
        message: 'A payment is already in progress.',
      );
    }

    final data = await _createRazorpayOrder(request);
    final keyId = data['keyId'] as String?;
    final orderId = data['orderId'] as String?;
    final amount = data['amount'] as int?;
    final currency = data['currency'] as String? ?? request.currency;

    if (keyId == null || orderId == null || amount == null) {
      return const PaymentCheckoutResult(
        success: false,
        message: 'Razorpay order response was incomplete.',
      );
    }

    _pendingBookingId = request.bookingId;
    _checkoutCompleter = Completer<PaymentCheckoutResult>();
    _razorpay.open(<String, Object?>{
      'key': keyId,
      'amount': amount,
      'currency': currency,
      'order_id': orderId,
      'name': 'Shootr',
      'description': request.description,
      'prefill': <String, Object?>{
        'name': request.customerName,
        'email': request.customerEmail,
        'contact': request.customerContact,
      },
    });
    return _checkoutCompleter!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _checkoutCompleter = null;
        _pendingBookingId = null;
        return const PaymentCheckoutResult(
          success: false,
          message: 'Payment timed out. Please try again.',
        );
      },
    );
  }

  Future<Map<Object?, Object?>> _createRazorpayOrder(
    PaymentRequest request,
  ) async {
    final payload = <String, Object?>{
      'amount': request.amount,
      'currency': request.currency,
      'bookingId': request.bookingId,
      'receipt': request.bookingId,
    };
    if (_backend.isEnabled) {
      return _backend
          .postJson('/api/create-razorpay-order', body: payload)
          .then((value) => value.cast<Object?, Object?>());
    }

    final result = await _functions
        .httpsCallable('createRazorpayOrder')
        .call<Map<Object?, Object?>>(payload);
    return result.data.cast<Object?, Object?>();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }

    try {
      final payload = <String, Object?>{
        'orderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature,
        'bookingId': _pendingBookingId,
      };
      if (_backend.isEnabled) {
        await _backend.postJson('/api/verify-razorpay-payment', body: payload);
      } else {
        await _functions.httpsCallable('verifyRazorpayPayment').call(payload);
      }
      completer.complete(
        PaymentCheckoutResult(
          success: true,
          orderId: response.orderId,
          paymentId: response.paymentId,
        ),
      );
    } catch (error) {
      completer.complete(
        PaymentCheckoutResult(
          success: false,
          orderId: response.orderId,
          paymentId: response.paymentId,
          message: error.toString(),
        ),
      );
    } finally {
      _checkoutCompleter = null;
      _pendingBookingId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(
      PaymentCheckoutResult(
        success: false,
        message: response.message ?? 'Payment failed.',
      ),
    );
    _checkoutCompleter = null;
    _pendingBookingId = null;
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final completer = _checkoutCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    completer.complete(
      PaymentCheckoutResult(
        success: false,
        message: 'External wallet selected: ${response.walletName ?? 'wallet'}',
      ),
    );
    _checkoutCompleter = null;
    _pendingBookingId = null;
  }

  void dispose() {
    _checkoutCompleter = null;
    _pendingBookingId = null;
    _razorpay.clear();
  }
}
