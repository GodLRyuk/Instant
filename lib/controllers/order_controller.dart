import 'package:get/get.dart';
import '../services/api_service.dart';

class OrderController extends GetxController {
  final ApiService _apiService = ApiService();
  var isLoading = false.obs;
  var orderList = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> createOrder({
    required List items,
    required dynamic address,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    await _apiService.createOrder(
      items: items,
      address_id: address.id,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      paymentStatus: "Paid",
    );
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;

      final data = await _apiService.getOrders();
      orderList.value = data;
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
