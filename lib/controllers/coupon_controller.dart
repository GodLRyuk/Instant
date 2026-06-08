import 'package:get/get.dart';
import 'package:instant_delivery/services/api_service.dart';

class CouponController extends GetxController {
  final ApiService _apiService = ApiService();

  // ── Observable state ──────────────────────────────────────────
  var isLoading = false.obs;
  var appliedCode = ''.obs; // e.g. "SAVE10"
  var discountAmount = 0.0.obs; // rupee discount to subtract
  var couponMessage = ''.obs; // success / error text shown in UI
  var isApplied = false.obs; // true when a valid coupon is active

  // ── Apply coupon ───────────────────────────────────────────────
  /// [code]       - raw text from the TextField (trimmed + uppercased inside)
  /// [orderTotal] - cart total BEFORE discount, BEFORE delivery charge
  Future<void> applyCoupon({
    required String code,
    required double orderTotal,
    required int totalQty,
  }) async {
    if (code.trim().isEmpty) {
      couponMessage.value = 'Please enter a coupon code.';
      return;
    }

    isLoading.value = true;
    couponMessage.value = '';

    try {
      final data = await _apiService.validateCoupon(
        code: code.trim().toUpperCase(),
        orderTotal: orderTotal,
      );

      if (data['success'] == true) {
        final minQty = (data['min_order_amount'] as num).toDouble();

        // ✅ CHECK MINIMUM QUANTITY
        if (totalQty < minQty) {
          _clearState();
          couponMessage.value =
              'Minimum $minQty items required to use this coupon.';
          return;
        }

        appliedCode.value = data['code'];
        discountAmount.value = (data['discount'] as num).toDouble();
        couponMessage.value = data['message'];
        isApplied.value = true;
      } else {
        _clearState();
        couponMessage.value = data['error'] ?? 'Failed to apply coupon.';
      }
    } catch (e) {
      _clearState();
      couponMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Remove coupon ──────────────────────────────────────────────
  void removeCoupon() {
    _clearState();
    couponMessage.value = 'Coupon removed.';
  }

  void _clearState() {
    appliedCode.value = '';
    discountAmount.value = 0.0;
    isApplied.value = false;
  }
}
