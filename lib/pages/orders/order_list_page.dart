import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/order_controller.dart';
import 'package:instant_delivery/pages/orders/order_detail_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class OrderPage extends StatelessWidget {
  OrderPage({super.key});

  final OrderController controller = Get.put(OrderController());

  Color getStatusColor(String status) {
    switch (status) {
      case "CONFIRMED":
        return Colors.greenAccent;
      case "COMPLETED":
        return Colors.green;
      case "PACKED":
        return Colors.green;
      case "SHIPPED":
        return Colors.yellow;
      case "PENDING":
        return Colors.orange;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const CustomAppBar(
        title: "My Orders",
        isTransparent: false,
        showBackButton: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.orderList.isEmpty) {
          return const Center(child: Text("No Orders Found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orderList.length,
          itemBuilder: (context, index) {
            final order = controller.orderList[index];
            final int orderId = (order['id']);

            final String status = (order['order_status'] ?? '').toString();

            final String amount = "₹${order['total_amount'] ?? 0}";

            final String date = (order['created_at'] ?? '').toString();

            final items = order['items'] ?? [];

            final String productName = items.isNotEmpty
                ? (items[0]['product_name'] ?? '')
                : '';

            Color statusColor = getStatusColor(status);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF9FAFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// TOP ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.inventory_2,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Order $productName",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        /// STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            order['order_status'].toUpperCase(),
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    /// AMOUNT (HIGHLIGHTED)
                    Text(
                      amount,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    /// DATE
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Placed on $date",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    /// DIVIDER
                    Divider(color: Colors.grey.shade200),

                    /// ACTION ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Get.to(() => OrderDetailPage(orderId: orderId));
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text("View Details"),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
