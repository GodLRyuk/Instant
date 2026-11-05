import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
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

  final WishlistController wishlistController = Get.find();

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

    final double cardWidth = width * (width < 360 ? 0.34 : 0.28);
    final double infoBlockHeight = cardWidth + (width < 360 ? 70 : 90);
    final double stripHeight = cardWidth + infoBlockHeight;

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
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
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
                        fontSize: width < 360 ? 15 : width * 0.045,
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

          SizedBox(height: height * 0.01),

          // Horizontal product cards
          SizedBox(
            height: stripHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.controller.flashSaleProducts.length,
              itemBuilder: (context, index) {
                final product = widget.controller.flashSaleProducts[index];
                final discountInt = product.discount_percent.toInt();

                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: GestureDetector(
                    onTap: () =>
                        Get.to(() => ProductDetailsPage(product: product)),
                    child: Container(
                      width: cardWidth,
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
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Image block ────────────────────────
                          AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF6F8F5),
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(14),
                                    ),
                                  ),
                                  child: CachedNetworkImage(
                                    imageUrl: product.image,
                                    fit: BoxFit.contain,
                                    placeholder: (_, _) => Icon(
                                      Icons.image,
                                      color: Colors.grey[300],
                                    ),
                                    errorWidget: (_, _, _) => Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                                ),

                                // Discount badge (top-left)
                                if (discountInt > 0)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade500,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        '-$discountInt%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Wishlist heart (top-right)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Obx(
                                    () => GestureDetector(
                                      onTap: () =>
                                          wishlistController.toggle(product),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          wishlistController.isWishlisted(
                                                product.id,
                                              )
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 12,
                                          color:
                                              wishlistController.isWishlisted(
                                                product.id,
                                              )
                                              ? const Color(0xFFE0386A)
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Info block ──────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // VIEW button on top of price
                                GestureDetector(
                                  onTap: () => Get.to(
                                    () => ProductDetailsPage(product: product),
                                  ),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "VIEW",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Price row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${product.discounted_price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 1.5,
                                      ),
                                      child: Text(
                                        '₹${product.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red.shade400,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 3),

                                // Name
                                Text(
                                  product.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
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
