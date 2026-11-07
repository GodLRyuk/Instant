import 'package:instant_delivery/widgets/app_snackbar.dart';
// lib/controllers/pass_controller.dart

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassController extends GetxController {
  final ApiService _api = ApiService();

  final hasPass = false.obs;
  final planType = ''.obs;
  final validUntil = ''.obs;
  final freeDeliveriesRemaining = 0.obs;
  final freeDeliveryCap = 20.obs; // ← add this
  final freeDeliveryMinOrder = 0.0.obs;
  final couponUnlockAt = 0.0.obs;
  final isLoading = false.obs;
  final isPurchasing = false.obs;

@override
void onInit() {
  super.onInit();
  Future.microtask(() => fetchPassStatus());
}

  Future<void> fetchPassStatus() async {
    try {
      isLoading.value = true;
      final data = await _api.getPassStatus();
      hasPass.value = data['has_pass'] ?? false;
      if (hasPass.value) {
        planType.value = data['plan_type'] ?? '';
        validUntil.value = data['valid_until'] ?? '';
        freeDeliveriesRemaining.value = data['free_deliveries_remaining'] ?? 0;
        freeDeliveryCap.value = data['free_delivery_cap'] ?? 20; // ← add this
        freeDeliveryMinOrder.value =
            double.tryParse(data['free_delivery_min_order'].toString()) ?? 149;
        couponUnlockAt.value =
            double.tryParse(data['coupon_unlock_at'].toString()) ?? 299;
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      hasPass.value = prefs.getBool('has_pass') ?? false;
      planType.value = prefs.getString('pass_plan_type') ?? '';
      validUntil.value = prefs.getString('pass_valid_until') ?? '';
      print("Pass status fallback to local: ${hasPass.value}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> purchasePass(String planType) async {
    try {
      isPurchasing.value = true;
      final result = await _api.purchasePass(planType: planType);
      if (result['statusCode'] == 200) {
        await fetchPassStatus();
        AppSnackbar.show(
          "🎉 Pass Activated!",
          result['data']['message'] ?? "Your pass is now active",
          snackPosition: SnackPosition.TOP,
        );
      } else {
        AppSnackbar.show(
          "Error",
          result['data']['error'] ?? "Something went wrong",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      AppSnackbar.show("Error", e.toString());
    } finally {
      isPurchasing.value = false;
    }
  }
}
