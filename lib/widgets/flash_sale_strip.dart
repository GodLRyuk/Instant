import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';

class FlashSaleStrip extends StatefulWidget {
  final ProductController controller;
  const FlashSaleStrip({super.key, required this.controller});

  @override
  State<FlashSaleStrip> createState() => _FlashSaleStripState();
}

class _FlashSaleStripState extends State<FlashSaleStrip> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final endTime = widget.controller.flashSaleEndTime.value;
    if (endTime == null) return;
    final diff = endTime.difference(DateTime.now());
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String get timerText {
    if (_remaining == Duration.zero) return '00:00:00';

    final days = _remaining.inDays;
    final h = _twoDigits(_remaining.inHours.remainder(24));
    final m = _twoDigits(_remaining.inMinutes.remainder(60));
    final s = _twoDigits(_remaining.inSeconds.remainder(60));

    if (days > 0) {
      return '${days}d ${h}h ${m}m'; // e.g. "2d 05h 30m"
    }
    return '$h:$m:$s'; // e.g. "05:30:22" when less than 1 day
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Obx(() {
      if (widget.controller.isFlashSaleLoading.value) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (widget.controller.flashSaleProducts.isEmpty) {
        return const SizedBox.shrink(); // hide if no active sale
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: width * 0.01),
                    Text(
                      widget.controller.flashSaleTitle.value,
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Countdown timer badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAEEDA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 14,
                            color: Color(0xFF854F0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timerText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF854F0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.008),

          // Horizontal product cards
          SizedBox(
            height: height * 0.24,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.controller.flashSaleProducts.length,
              itemBuilder: (context, index) {
                final product = widget.controller.flashSaleProducts[index];
                final discountInt = product.discount_percent.toInt();

                return GestureDetector(
                  onTap: () =>
                      Get.to(() => ProductDetailsPage(product: product)),
                  child: Container(
                    width: width * 0.38,
                    margin: EdgeInsets.only(
                      left: width * 0.04,
                      right:
                          index ==
                              widget.controller.flashSaleProducts.length - 1
                          ? width * 0.04
                          : 0,
                      bottom: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(width * 0.04),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Discount badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountInt%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          // Product image
                          Expanded(
                            child: Center(
                              child: Image.network(
                                product.image,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),

                          // Name
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: width * 0.032,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: height * 0.003),

                          // Prices row
                          Row(
                            children: [
                              Text(
                                '₹${product.discounted_price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.035,
                                ),
                              ),
                              SizedBox(width: width * 0.02),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: width * 0.028,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: height * 0.006),

                          // Add button
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: height * 0.007,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(width * 0.02),
                            ),
                            child: Center(
                              child: Text(
                                'View',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.032,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: height * 0.015),
        ],
      );
    });
  }
}
