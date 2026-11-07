import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/controllers/pass_controller.dart';
import 'package:flutter/material.dart';

class PassPaymentController extends GetxController {
  final ApiService _apiService = ApiService();
  late Razorpay _razorpay;

  final isLoading = false.obs;

  // Pending pass details — stored before Razorpay opens
  String? _pendingPlanType;
  double? _pendingAmount;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
  }

  Future<void> purchasePass({
    required String planType,
    required double amount,
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      // Store pending details — used after Razorpay success
      _pendingPlanType = planType;
      _pendingAmount = amount;

      // Open Razorpay
      final options = {
        'key': AppConfig.razorpayKey,
        'amount': (amount * 100).toInt(),
        'name': 'Instant Delivery',
        'description':
            '${planType == "MONTHLY" ? "Monthly" : "Yearly"} Delivery Pass',
        'prefill': {
          'contact': prefs.getString('phone') ?? '',
          'email': prefs.getString('email') ?? '',
        },
        'theme': {'color': '#4CAF50'},
      };

      _razorpay.open(options);
    } catch (e) {
      AppSnackbar.show("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Razorpay success → activate pass on backend ───────────────
  void _handleSuccess(PaymentSuccessResponse response) async {
    await _activatePass(razorpayPaymentId: response.paymentId);
  }

  Future<void> _activatePass({String? razorpayPaymentId}) async {
    try {
      isLoading.value = true;

      final result = await _apiService.purchasePass(
        planType: _pendingPlanType!,
      );

      final statusCode = result['statusCode'];
      final data = result['data'];

      if (statusCode == 200) {
        // ✅ Save pass details locally
        await _savePassLocally(
          planType: _pendingPlanType!,
          amount: _pendingAmount!,
          validUntil: data['valid_until'] ?? '',
          razorpayPaymentId: razorpayPaymentId ?? '',
        );

        // ✅ Refresh PassController so UI updates immediately
        if (Get.isRegistered<PassController>()) {
          await Get.find<PassController>().fetchPassStatus();
        }

        _clearPending();

        // ✅ Show success sheet
        _showSuccessSheet(
          planType: _pendingPlanType ?? 'MONTHLY',
          validUntil: data['valid_until'] ?? '',
        );
      } else {
        _showErrorSheet(data['error'] ?? 'Pass activation failed.');
      }
    } catch (e) {
      _showErrorSheet('Something went wrong. Contact support.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Save pass to SharedPreferences ───────────────────────────
  Future<void> _savePassLocally({
    required String planType,
    required double amount,
    required String validUntil,
    required String razorpayPaymentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_pass', true);
    await prefs.setString('pass_plan_type', planType);
    await prefs.setDouble('pass_amount_paid', amount);
    await prefs.setString('pass_valid_until', validUntil);
    await prefs.setString('pass_payment_id', razorpayPaymentId);
    await prefs.setString(
      'pass_purchased_at',
      DateTime.now().toIso8601String(),
    );
  }

  void _clearPending() {
    _pendingPlanType = null;
    _pendingAmount = null;
  }

  // ── Razorpay error ────────────────────────────────────────────
  void _handleError(PaymentFailureResponse response) {
    AppSnackbar.show(
      "Payment Failed",
      response.message ?? "Something went wrong",
      snackPosition: SnackPosition.TOP,
    );
  }

  void _handleWallet(ExternalWalletResponse response) {
    AppSnackbar.show(
      "Wallet",
      response.walletName ?? "",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ── Success bottom sheet ──────────────────────────────────────
  void _showSuccessSheet({
    required String planType,
    required String validUntil,
  }) {
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
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: Colors.green.shade600,
                size: 48,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "Pass Activated! 🎉",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              "${planType == 'MONTHLY' ? 'Monthly' : 'Yearly'} Delivery Pass is now active",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              "Valid until $validUntil",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 20),

            // Benefits summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  _benefitRow("✅ Free delivery on orders above ₹149"),
                  _benefitRow("✅ Exclusive member-only coupons"),
                  _benefitRow("✅ Coupons unlock at ₹299+"),
                  _benefitRow("✅ Up to 20 free deliveries/month"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CTA
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
                  Get.back(); // close sheet
                  Get.back(); // go back from PassPurchasePage
                },
                child: const Text(
                  "Start Shopping",
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
      isDismissible: false, // force user to tap button
    );
  }

  // ── Error bottom sheet ────────────────────────────────────────
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
                Icons.error_outline,
                color: Colors.red.shade400,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Activation Failed",
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
                  "Try Again",
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

  Widget _benefitRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [Text(text, style: const TextStyle(fontSize: 13))]),
    );
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
