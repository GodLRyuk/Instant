import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/payment_controller.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;
  final List items;
  final dynamic address;
  final String? couponCode;
  final String? currentLat;
  final String? currentLng;
  final String deliveryType;
  final String? scheduledDate;
  final String? scheduledSlotStart;
  final String? scheduledSlotEnd;

  const PaymentPage({
    super.key,
    required this.totalAmount,
    required this.items,
    required this.address,
    this.couponCode,
    this.currentLat,
    this.currentLng,
    this.deliveryType = 'ASAP',
    this.scheduledDate,
    this.scheduledSlotStart,
    this.scheduledSlotEnd,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String selectedPayment = "GPay";
  final PaymentController paymentController = Get.put(PaymentController());

  // Tracks whether processPayment() is currently in flight, so we can
  // show a spinner and block duplicate taps on "Proceed to Pay".
  final RxBool isProcessingPayment = false.obs;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Payment",
        isTransparent: false,
        showBackButton: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          /// 🧾 ORDER SUMMARY (small preview)
          Container(
            margin: const EdgeInsets.all(18),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${widget.items.length} items"),
                Text(
                  "₹${widget.totalAmount}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

          /// 💳 PAYMENT SECTION
          Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Options",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _paymentCard("Google Pay", "GPay", Icons.g_mobiledata),
                _paymentCard("PhonePe", "PhonePe", Icons.phone_android),
                _paymentCard("Paytm", "Paytm", Icons.account_balance_wallet),
                _paymentCard("Cash on Delivery", "COD", Icons.money),
              ],
            ),
          ),

          /// 🟢 PAY BUTTON
          Container(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.green.shade300,
                  ),
                  onPressed: isProcessingPayment.value
                      ? null
                      : () async {
                          isProcessingPayment.value = true;
                          try {
                            await paymentController.processPayment(
                              items: widget.items,
                              address: widget.address,
                              totalAmount: widget.totalAmount,
                              paymentMethod: selectedPayment,
                              couponCode: widget.couponCode,
                              currentLat: widget.currentLat,
                              currentLng: widget.currentLng,
                              // ✅ add these
                              deliveryType: widget.deliveryType,
                              scheduledDate: widget.scheduledDate,
                              scheduledSlotStart: widget.scheduledSlotStart,
                              scheduledSlotEnd: widget.scheduledSlotEnd,
                            );
                          } finally {
                            // Always clear the loading state, whether the
                            // payment succeeded, failed, or threw — and
                            // whether or not this page is still mounted
                            // (e.g. if processPayment navigated away).
                            if (mounted) {
                              isProcessingPayment.value = false;
                            }
                          }
                        },
                  child: isProcessingPayment.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Proceed to Pay",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 PAYMENT CARD
  Widget _paymentCard(String title, String value, IconData icon) {
    bool isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  /// 🔥 COD ORDER
  void placeOrderCOD() {
    AppSnackbar.show("Success", "Order placed with Cash on Delivery");
    // 👉 Call your order API here
  }

  /// 🔥 UPI
  Future<void> openUpiApp({
    required String upiId,
    required String name,
    required String amount,
    required String note,
  }) async {
    final Uri uri = Uri.parse(
      "upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=$note",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppSnackbar.show("Error", "No UPI app found");
    }
  }
}
