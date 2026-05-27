import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:instant_delivery/services/api_service.dart';

class OrderDetailController extends GetxController {
  final ApiService _api = ApiService();

  var isLoading = false.obs;
  var orderDetail = {}.obs;

  Future<void> fetchOrderDetail(int orderId) async {
    try {
      isLoading.value = true;

      final data = await _api.getOrderDetail(orderId);
      orderDetail.value = data;

    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}