import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/pages/orders/order_list_page.dart';
import 'package:instant_delivery/widgets/navigation/bottom_navigation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PaymentController extends GetxController {
  var isLoading = false.obs;

  late Razorpay _razorpay;
  final ApiService _apiService = ApiService();

  // ✅ Store pending order details
  List? _pendingItems;
  dynamic _pendingAddress;
  double? _pendingAmount;
  String? _pendingMethod;
  String? _pendingCouponCode;

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
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      // ✅ Save for use after payment success
      _pendingItems = items;
      _pendingAddress = address;
      _pendingAmount = totalAmount;
      _pendingMethod = paymentMethod;
      _pendingCouponCode = couponCode;

      // ✅ Open Razorpay directly — no order created yet
      var options = {
        'key': 'rzp_test_StsVgck8iNAA8a',
        'amount': (totalAmount * 100).toInt(), // paise
        'name': 'Instant Delivery',
        'description': 'Order Payment',
        'prefill': {
          'contact': prefs.getString('phone') ?? '',
          'email': prefs.getString('email') ?? '',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ SUCCESS — create order only now
  void _handleSuccess(PaymentSuccessResponse response) async {
    try {
      isLoading.value = true;

      // ✅ Now create the order
      final res = await _apiService.createOrder(
        items: _pendingItems!,
        address_id: _pendingAddress!.id,
        totalAmount: _pendingAmount!,
        paymentMethod: _pendingMethod!,
        paymentStatus: "PAID",
        couponCode: _pendingCouponCode,
      );

      final orderId = res["data"]["order_id"];
      final resData = res["data"];
      final statusCode = res["statusCode"];
      if (statusCode == 400 && orderId == null) {
        final errorMsg =
            resData["pincode"] ?? resData["error"] ?? "Order creation failed";
        // Get.snackbar("Error", errorMsg);
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
                // ── Drag handle ──
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // ── Icon ──
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

                // ── Title ──
                const Text(
                  "Delivery Unavailable",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // ── Message ──
                Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 24),

                // ── Button ──
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
                    onPressed: () {
                      Get.back();
                      // Get.offAll(() => const MainNavigation(initialIndex: 2));
                    },
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
        return;
      }

      // ✅ Clear pending data
      _pendingItems = null;
      _pendingAddress = null;
      _pendingAmount = null;
      _pendingMethod = null;

      Get.snackbar(
        "Success",
        "Order Placed Successfully!",
        snackPosition: SnackPosition.TOP,
      );

      // ✅ Navigate to success page
      Get.offAll(() => const MainNavigation(initialIndex: 2));
    } catch (e) {
      Get.snackbar(
        "Error",
        "Order creation failed — contact support",
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ❌ ERROR — nothing to cancel since order was never created
  void _handleError(PaymentFailureResponse response) {
    Get.snackbar(
      "Payment Failed",
      response.message ?? "Something went wrong",
      snackPosition: SnackPosition.TOP,
    );
    Get.back();
  }

  // 💳 WALLET
  void _handleWallet(ExternalWalletResponse response) {
    Get.snackbar("Wallet", response.walletName ?? "");
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
