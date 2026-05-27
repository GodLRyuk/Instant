import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/orderDetails_controller.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId; // 🔥 use ID instead of Map

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderDetailController controller = Get.put(OrderDetailController());

  @override
  void initState() {
    super.initState();

    // 🔥 FETCH ORDER FROM API
    controller.fetchOrderDetail(widget.orderId);
  }

  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "CONFIRMED":
        return Colors.blue;
      case "COMPLETED":
        return Colors.green;
      case "SHIPPED":
        return Colors.orange;
      case "PENDING":
        return Colors.grey;
      case "CANCELLED":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Order Details",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final order = controller.orderDetail;

        if (order.isEmpty) {
          return const Center(child: Text("No Order Found"));
        }

        final items = order['items'] ?? [];
        final address = order['address'] ?? {};
        final status = (order['order_status'] ?? '').toString();
        final statusColor = getStatusColor(status);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔵 ORDER STATUS
              _sectionTitle("Order Status"),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, color: statusColor),
                    const SizedBox(width: 10),
                    Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 📦 PRODUCTS
              _sectionTitle("Products"),
              ...items.map<Widget>((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),

                      /// product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['product_name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Qty: ${item['quantity'] ?? 0}"),
                          ],
                        ),
                      ),

                      Text(
                        "₹${item['total_price'] ?? item['price'] ?? 0}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 20),

              /// 🚚 SHIPPING DETAILS
              _sectionTitle("Shipping Details"),
              _infoRow("Name", address['name'] ?? '-'),
              _infoRow("Phone", address['phone'] ?? '-'),
              _infoRow("Address", address['full_address'] ?? '-'),
              _infoRow("City", address['city'] ?? '-'),
              _infoRow("Pincode", address['pincode'] ?? '-'),

              const SizedBox(height: 20),

              /// 💳 PAYMENT DETAILS
              _sectionTitle("Payment"),
              _infoRow("Payment Status", order['payment_status'] ?? '-'),
              _infoRow("Total Amount", "₹${order['total_amount'] ?? 0}"),
              _infoRow("Discount", "₹${order['discount_amount'] ?? 0}"),

              const SizedBox(height: 20),

              /// 📍 DELIVERY INFO
              _sectionTitle("Delivery"),
              _infoRow("Status", status),
              _infoRow(
                "Placed On",
                order['created_at'] != null
                    ? DateFormat(
                        'dd-MM-yyyy',
                      ).format(DateTime.parse(order['created_at']))
                    : '-',
              ),
            ],
          ),
        );
      }),
    );
  }

  /// 🔹 Section Title
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  /// 🔹 Info Row
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, softWrap: true)),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
