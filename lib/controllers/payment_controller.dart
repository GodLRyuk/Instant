import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PaymentController extends GetxController {
  var isLoading = false.obs;

  late Razorpay _razorpay;
  final ApiService _apiService = ApiService();

  // Store pending order details (used in _handleSuccess after payment)
  List? _pendingItems;
  dynamic _pendingAddress;
  double? _pendingAmount;
  String? _pendingMethod;
  String? _pendingCouponCode;
  String? _currentLat;
  String? _currentLng;
  String? _pendingDeliveryType;
  String? _pendingScheduledDate;
  String? _pendingScheduledSlotStart;
  String? _pendingScheduledSlotEnd;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  Future<void> processPayment({
    required List items,
    required dynamic address,
    required double totalAmount,
    required String paymentMethod,
    String? couponCode,
    String? currentLat,
    String? currentLng,
    String deliveryType = 'ASAP',
    String? scheduledDate,
    String? scheduledSlotStart,
    String? scheduledSlotEnd,
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      // STEP 1: VALIDATE ONLY — no order created yet
      // checks location, pincode, stock
      final validateRes = await _apiService.validateOrder(
        items: items,
        addressId: address.id,
        currentLat: currentLat,
        currentLng: currentLng,
      );

      final validateStatus = validateRes["statusCode"];
      final validateData = validateRes["data"];

      if (validateStatus == 400) {
        final data = validateData;
        String errorMsg = "Validation failed. Please try again.";

        if (data is List && data.isNotEmpty) {
          errorMsg = data.first.toString();
        } else if (data is Map) {
          final val = data.values.first;
          errorMsg = val is List ? val.first.toString() : val.toString();
        }

        _showErrorSheet(errorMsg);
        return;
      }
      if (validateStatus != 200) {
        _showErrorSheet("Something went wrong. Please try again.");
        return;
      }

      // STEP 2: Validation passed — save details for after payment
      _pendingItems = items;
      _pendingAddress = address;
      _pendingAmount = totalAmount;
      _pendingMethod = paymentMethod;
      _pendingCouponCode = couponCode;
      _currentLat = currentLat;
      _currentLng = currentLng;
      _pendingDeliveryType = deliveryType;
      _pendingScheduledDate = scheduledDate;
      _pendingScheduledSlotStart = scheduledSlotStart;
      _pendingScheduledSlotEnd = scheduledSlotEnd;

      // COD: skip Razorpay, go straight to createOrder
      if (paymentMethod == "COD") {
        await _createOrder(paymentStatus: "PENDING");
        return;
      }

      // STEP 3: Open Razorpay — only if validation passed
      var options = {
        'key': AppConfig.razorpayKey,
        'amount': (totalAmount * 100).toInt(),
        'name': 'Instant Delivery',
        'description': 'Order Payment',
        'prefill': {
          'contact': prefs.getString('phone') ?? '',
          'email': prefs.getString('email') ?? '',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      AppSnackbar.show("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Payment succeeded — NOW create the order
  void _handleSuccess(PaymentSuccessResponse response) async {
    await _createOrder(paymentStatus: "PAID");
  }

  // Shared order creation (called after Razorpay success or for COD)
  Future<void> _createOrder({required String paymentStatus}) async {
    try {
      isLoading.value = true;

      final res = await _apiService.createOrder(
        items: _pendingItems!,
        address_id: _pendingAddress!.id,
        totalAmount: _pendingAmount!,
        paymentMethod: _pendingMethod!,
        paymentStatus: paymentStatus,
        couponCode: _pendingCouponCode,
        currentLat: _currentLat,
        currentLng: _currentLng,
        deliveryType: _pendingDeliveryType ?? 'ASAP',
        scheduledDate: _pendingScheduledDate,
        scheduledSlotStart: _pendingScheduledSlotStart,
        scheduledSlotEnd: _pendingScheduledSlotEnd,
      );

      final statusCode = res["statusCode"];
      final resData = res["data"];

      // Extremely unlikely to fail here since we pre-validated,
      // but handle gracefully just in case (e.g. race condition on stock)
      if (statusCode == 400) {
        final errorMsg =
            resData["location"] ??
            resData["pincode"] ??
            resData["error"] ??
            "Order creation failed";
        _showErrorSheet(errorMsg);
        return;
      }

      _clearPending();

      AppSnackbar.show(
        "Success",
        "Order Placed Successfully!",
        snackPosition: SnackPosition.TOP,
      );

      Get.offAll(() => const MainNavigation(initialIndex: 2));
    } catch (e) {
      AppSnackbar.show(
        "Error",
        "Order creation failed — contact support",
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _clearPending() {
    _pendingItems = null;
    _pendingAddress = null;
    _pendingAmount = null;
    _pendingMethod = null;
    _pendingCouponCode = null;
    _currentLat = null;
    _currentLng = null;
    _pendingDeliveryType = null;
    _pendingScheduledDate = null;
    _pendingScheduledSlotStart = null;
    _pendingScheduledSlotEnd = null;
  }

  // Payment cancelled/failed — no order was created, nothing to clean up
  void _handleError(PaymentFailureResponse response) {
    AppSnackbar.show(
      "Payment Failed",
      response.message ?? "Something went wrong",
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleWallet(ExternalWalletResponse response) {
    AppSnackbar.show("Wallet", response.walletName ?? "");
  }

  void _showErrorSheet(String message) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.red.shade400,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Order Failed",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Get.back(),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
