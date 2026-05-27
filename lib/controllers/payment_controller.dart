import 'package:get/get.dart';
import 'package:instant_delivery/pages/orders/order_list_page.dart';
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
  }) async {
    try {
      isLoading.value = true;

      final prefs = await SharedPreferences.getInstance();

      // ✅ Save for use after payment success
      _pendingItems = items;
      _pendingAddress = address;
      _pendingAmount = totalAmount;
      _pendingMethod = paymentMethod;

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
      );

      final orderId = res["data"]["order_id"];

      if (orderId == null) {
        Get.snackbar("Error", "Order creation failed");
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
      Get.offAll(() => OrderPage());
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
