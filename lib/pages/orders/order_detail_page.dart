import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/orderDetails_controller.dart';
import 'package:instant_delivery/widgets/branding/branding.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:instant_delivery/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderDetailController controller = Get.put(OrderDetailController());

  // ── Status step order ─────────────────────────────────
  static const _steps = [
    'PENDING',
    'CONFIRMED',
    'ASSIGNED',
    'SHIPPED',
    'DELIVERED',
  ];

  int _currentStep(String status, bool hasDriver) {
    if (status == 'CONFIRMED' && hasDriver) return 2; // ASSIGNED
    final idx = _steps.indexOf(status.toUpperCase());
    return idx == -1 ? 0 : idx;
  }

  @override
  void initState() {
    super.initState();
    controller.fetchOrderDetail(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const CustomAppBar(
        title: "Order Details",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const OrderDetailSkeleton();
        }

        final order = controller.orderDetail;
        if (order.isEmpty) {
          return const Center(child: Text("No Order Found"));
        }

        final items = order['items'] ?? [];
        final address = order['address'] ?? {};
        final status = (order['order_status'] ?? 'PENDING')
            .toString()
            .toUpperCase();
        final deliveryType = (order['delivery_type'] ?? 'ASAP')
            .toString()
            .toUpperCase();
        final isScheduled = deliveryType == 'SCHEDULED';
        final isCancelled = status == 'CANCELLED';
        final deliveryOtp = order['delivery_otp']?.toString().trim();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── ORDER ID + DATE ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order #${order['id'] ?? widget.orderId}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (order['created_at'] != null)
                    Text(
                      DateFormat(
                        'dd MMM, hh:mm a',
                      ).format(DateTime.parse(order['created_at']).toLocal()),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // ── DELIVERY TYPE BADGE ──────────────────────────
              Row(
                children: [
                  _deliveryBadge(isScheduled),
                  const SizedBox(width: 8),
                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        "Cancelled",
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // ── PROGRESS TRACKER ────────────────────────────────────
              if (!isCancelled)
                _buildProgressTracker(status, order)
              else
                _buildCancelledCard(),

              const SizedBox(height: 20),

              // if (deliveryOtp != null && deliveryOtp.isNotEmpty) ...[
              _buildDeliveryOtpCard(deliveryOtp!),
              const SizedBox(height: 20),
              // ],

              // ── SCHEDULED INFO (if applicable) ───────────────
              if (isScheduled) _buildScheduledCard(order),

              const SizedBox(height: 0),

              // ── PAYMENT ──────────────────────────────────────
              _buildPaymentCard(order),

              const SizedBox(height: 10),

              // ── ITEMS ────────────────────────────────────────
              _sectionTitle("Items Ordered"),
              ...items.map<Widget>((item) => _buildItemCard(item)).toList(),

              const SizedBox(height: 10),

              // ── PRICE SUMMARY ────────────────────────────────
              _buildPriceSummary(order),

              const SizedBox(height: 20),

              // ── DELIVERY ADDRESS ─────────────────────────────
              _buildAddressCard(address),
            ],
          ),
        );
      }),
      bottomNavigationBar: const AppFooterBranding(),
    );
  }

  // ── DELIVERY TYPE BADGE ──────────────────────────────────
  Widget _deliveryBadge(bool isScheduled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isScheduled ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isScheduled ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScheduled ? Icons.calendar_month : Icons.bolt,
            size: 14,
            color: isScheduled ? Colors.blue.shade700 : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            isScheduled ? "Scheduled Delivery" : "ASAP Delivery",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isScheduled ? Colors.blue.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOtpCard(String otp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.amber.shade800, size: 18),
              const SizedBox(width: 8),
              const Text(
                "Delivery OTP",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            otp,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Share this code with your delivery partner to confirm delivery.",
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── PROGRESS TRACKER ────────────────────────────────────
  Widget _buildProgressTracker(String status, Map order) {
    // Check if driver is assigned from order data
    final driverName = order['driver_name'] ?? order['assigned_driver'];
    final hasDriver = driverName != null && driverName.toString().isNotEmpty;
    final current = _currentStep(status, hasDriver);

    final stepIcons = [
      Icons.receipt_long,
      Icons.check_circle_outline,
      Icons.delivery_dining, // ✅ driver assigned
      Icons.local_shipping,
      Icons.home,
    ];
    final stepLabels = [
      'Order\nPlaced',
      'Confirmed',
      'Driver\nAssigned',
      'On the\nWay',
      'Delivered',
    ];
    final stepColors = [
      Colors.grey.shade400,
      Colors.blue,
      Colors.purple, // ✅ distinct color for driver step
      Colors.orange,
      const Color(0xFF3CB549),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Delivery Progress",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Step indicators
          Row(
            children: List.generate(_steps.length, (i) {
              final isDone = i <= current;
              final isActive = i == current;
              final color = isDone ? stepColors[i] : Colors.grey.shade300;

              return Expanded(
                child: Column(
                  children: [
                    // Line + circle row
                    Row(
                      children: [
                        // Left line
                        if (i > 0)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i <= current
                                  ? stepColors[i]
                                  : Colors.grey.shade200,
                            ),
                          ),

                        // Circle
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 40 : 32,
                          height: isActive ? 40 : 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone ? color : Colors.grey.shade100,
                            border: Border.all(
                              color: isDone ? color : Colors.grey.shade300,
                              width: isActive ? 3 : 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            stepIcons[i],
                            size: isActive ? 20 : 16,
                            color: isDone ? Colors.white : Colors.grey.shade400,
                          ),
                        ),

                        // Right line
                        if (i < _steps.length - 1)
                          Expanded(
                            child: Container(
                              height: 3,
                              color: i < current
                                  ? stepColors[i + 1]
                                  : Colors.grey.shade200,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Label
                    Text(
                      stepLabels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isDone ? stepColors[i] : Colors.grey.shade400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 16),

          // Status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _statusMessageColor(status).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _statusMessageIcon(status),
                  color: _statusMessageColor(status),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusMessage(status),
                    style: TextStyle(
                      color: _statusMessageColor(status),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Add inside _buildProgressTracker, after the status message container
          if (hasDriver) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.purple.shade100,
                    child: Text(
                      driverName.toString()[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$driverName is on the way!",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "Your delivery partner has been assigned.",
                          style: TextStyle(
                            color: Colors.purple.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified_user,
                    color: Colors.purple.shade300,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CANCELLED CARD ───────────────────────────────────────
  Widget _buildCancelledCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel, color: Colors.red.shade600, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Cancelled",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "This order has been cancelled.",
                  style: TextStyle(color: Colors.red.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SCHEDULED CARD ───────────────────────────────────────
  Widget _buildScheduledCard(Map order) {
    final date = order['scheduled_date'];
    final slotStart = order['scheduled_slot_start'];
    final slotEnd = order['scheduled_slot_end'];

    if (date == null) return const SizedBox.shrink();

    String formattedDate = '-';
    try {
      formattedDate = DateFormat(
        'EEEE, dd MMM yyyy',
      ).format(DateTime.parse(date));
    } catch (_) {
      formattedDate = date;
    }

    String formatTime(String? t) {
      if (t == null) return '-';
      try {
        final parts = t.split(':');
        int h = int.parse(parts[0]);
        final m = parts[1];
        final period = h >= 12 ? 'PM' : 'AM';
        if (h > 12) h -= 12;
        if (h == 0) h = 12;
        return '$h:$m $period';
      } catch (_) {
        return t;
      }
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 60, 169, 69),
                const Color.fromARGB(255, 52, 163, 186),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Scheduled Delivery",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                formattedDate,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${formatTime(slotStart)} – ${formatTime(slotEnd)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ITEMS ─────────────────────────────────────────────────
  Widget _buildItemCard(Map item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Color(0xFF3CB549),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['product_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Qty: ${item['quantity'] ?? 0}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "₹${item['total_price'] ?? item['price'] ?? 0}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── PRICE SUMMARY ─────────────────────────────────────────
  Widget _buildPriceSummary(Map order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Price Summary",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _priceRow("Subtotal", "₹${order['total_amount'] ?? 0}"),
          _priceRow("Delivery Fee", "₹${order['delivery_fee'] ?? 0}"),
          if ((order['discount_amount'] ?? 0).toString() != '0.00' &&
              (order['discount_amount'] ?? 0).toString() != '0')
            _priceRow(
              "Discount",
              "-₹${order['discount_amount']}",
              color: Colors.green,
            ),
          const Divider(height: 20),
          _priceRow("Total", "₹${order['total_amount'] ?? 0}", bold: true),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black87,
              fontSize: bold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── ADDRESS CARD ──────────────────────────────────────────
  Widget _buildAddressCard(Map address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFF3CB549), size: 18),
              const SizedBox(width: 6),
              const Text(
                "Delivery Address",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (address['name'] != null && address['name'] != 'null')
            Text(
              address['name'],
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          if (address['phone'] != null && address['phone'] != 'null')
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                address['phone'],
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            "${address['full_address'] ?? ''}, ${address['city'] ?? ''} - ${address['pincode'] ?? ''}",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── PAYMENT CARD ──────────────────────────────────────────
  Widget _buildPaymentCard(Map order) {
    final isPaid =
        (order['payment_status'] ?? '').toString().toUpperCase() == 'PAID';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.04)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.pending,
              color: isPaid ? Colors.green : Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? "Payment Confirmed" : "Payment Pending",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
                Text(
                  order['payment_method'] ?? 'COD',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────
  String _statusMessage(String status) {
    switch (status) {
      case 'PENDING':
        return 'Your order is placed and waiting to be confirmed.';
      case 'CONFIRMED':
        return 'Your order is confirmed and being packed.';
      case 'SHIPPED':
        return 'Your order is on the way! Delivery in progress.';
      case 'DELIVERED':
        return 'Your order has been delivered. Enjoy!';
      default:
        return 'Order status updated.';
    }
  }

  Color _statusMessageColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.grey.shade600;
      case 'CONFIRMED':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.orange;
      case 'DELIVERED':
        return const Color(0xFF3CB549);
      default:
        return Colors.grey;
    }
  }

  IconData _statusMessageIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_top;
      case 'CONFIRMED':
        return Icons.check_circle_outline;
      case 'SHIPPED':
        return Icons.delivery_dining;
      case 'DELIVERED':
        return Icons.celebration;
      default:
        return Icons.info_outline;
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
