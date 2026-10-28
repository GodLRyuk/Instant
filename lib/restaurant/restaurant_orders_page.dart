import 'package:flutter/material.dart';

import '../models/restaurant_models.dart';
import '../models/restaurant_module.dart';
import '../services/restaurant_api.dart';
import '../widgets/restaurant_widgets.dart';

class RestaurantOrdersPage extends StatefulWidget {
  const RestaurantOrdersPage({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  State<RestaurantOrdersPage> createState() => _RestaurantOrdersPageState();
}

class _RestaurantOrdersPageState extends State<RestaurantOrdersPage> {
  List<PlacedOrder> _orders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await RestaurantModule.api.myOrders();
      if (!mounted) return;
      orders.sort((a, b) {
        final aDate = a.createdAt;
        final bDate = b.createdAt;
        if (aDate == null) return bDate == null ? 0 : 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });
      setState(() => _orders = orders);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is RestaurantApiException
            ? error.message
            : 'Could not load restaurant orders.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RColors.bg,
      body: Column(
        children: [
          if (widget.showHeader)
            const RestaurantHeader(title: 'Restaurant orders'),
          Expanded(
            child: _loading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _orders.isEmpty
                ? _OrdersError(message: _error!, onRetry: _loadOrders)
                : RefreshIndicator(
                    onRefresh: _loadOrders,
                    child: _orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 140),
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 56,
                                color: RColors.muted,
                              ),
                              SizedBox(height: 14),
                              Center(
                                child: Text(
                                  'No restaurant orders yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Center(
                                child: Text(
                                  'Your restaurant orders will appear here.',
                                  style: TextStyle(color: RColors.muted),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            itemCount: _orders.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) =>
                                _RestaurantOrderCard(order: _orders[index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantOrderCard extends StatelessWidget {
  const _RestaurantOrderCard({required this.order});

  final PlacedOrder order;

  static const _progressStages = [
    'Placed',
    'Accepted',
    'Preparing',
    'Ready',
    'On way',
    'Delivered',
  ];

  int? _progressIndex(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'placed':
      case 'pending':
        return 0;
      case 'confirmed':
      case 'accepted':
        return 1;
      case 'preparing':
        return 2;
      case 'ready':
        return 3;
      case 'out_for_delivery':
      case 'shipped':
        return 4;
      case 'delivered':
      case 'completed':
        return 5;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order.statusLabel.isNotEmpty
        ? order.statusLabel
        : order.status;
    final progressIndex = _progressIndex(order.status);
    final isCancelled = {
      'cancelled',
      'canceled',
      'rejected',
      'failed',
    }.contains(order.status.toLowerCase());
    final createdAt = order.createdAt?.toLocal();
    final dateText = createdAt == null
        ? null
        : '${createdAt.day.toString().padLeft(2, '0')}/'
              '${createdAt.month.toString().padLeft(2, '0')}/'
              '${createdAt.year} · '
              '${createdAt.hour.toString().padLeft(2, '0')}:'
              '${createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.restaurant, color: RColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Order ${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: RColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: RColors.darkGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (dateText != null) ...[
            const SizedBox(height: 12),
            Text(
              dateText,
              style: const TextStyle(fontSize: 12, color: RColors.muted),
            ),
          ],
          if (progressIndex != null) ...[
            const SizedBox(height: 18),
            _OrderProgress(
              currentIndex: progressIndex,
              stages: _progressStages,
            ),
          ] else if (isCancelled) ...[
            const SizedBox(height: 14),
            const Text(
              'This order was cancelled.',
              style: TextStyle(
                color: RColors.red,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (order.deliveryOtp != null &&
              order.deliveryOtp!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            _DeliveryOtpCard(otp: order.deliveryOtp!.trim()),
          ],
          const Divider(height: 22),
          Text(
            order.itemsText.isEmpty ? 'Order items' : order.itemsText,
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${order.paymentMethod.toUpperCase()} · ${order.paymentStatus}',
                  style: const TextStyle(fontSize: 12, color: RColors.muted),
                ),
              ),
              Text(
                rupees(order.total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: RColors.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryOtpCard extends StatelessWidget {
  const _DeliveryOtpCard({required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
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
                'Delivery OTP',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            otp,
            style: TextStyle(
              color: Colors.amber.shade900,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Share this code with your delivery partner to confirm delivery.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.currentIndex, required this.stages});

  final int currentIndex;
  final List<String> stages;

  @override
  Widget build(BuildContext context) {
    final progress = currentIndex / (stages.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order progress · ${stages[currentIndex]}',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFE7EAE8),
            color: RColors.green,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            for (var index = 0; index < stages.length; index++)
              Expanded(
                child: Text(
                  stages[index],
                  textAlign: index == 0
                      ? TextAlign.left
                      : index == stages.length - 1
                      ? TextAlign.right
                      : TextAlign.center,
                  style: TextStyle(
                    color: index <= currentIndex
                        ? RColors.darkGreen
                        : RColors.muted,
                    fontSize: 9,
                    fontWeight: index == currentIndex
                        ? FontWeight.w800
                        : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: RColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
