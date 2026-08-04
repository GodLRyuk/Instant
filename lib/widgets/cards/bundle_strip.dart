import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import '../../controllers/bundle_controller.dart';
import '../../models/bundle_model.dart';

final String _kApiBaseUrl = AppConfig.baseUrl;

String _resolveImageUrl(String rawUrl) {
  if (rawUrl.isEmpty) return rawUrl;
  if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
    return rawUrl;
  }
  // Relative path — prepend the base URL.
  final path = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
  return '$_kApiBaseUrl$path';
}

class BundleStrip extends StatelessWidget {
  const BundleStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final BundleController controller = Get.put(BundleController());
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Obx(() {
      if (controller.isLoading.value) {
        return const SizedBox(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.bundleList.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_basket,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Bundle Offers',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.01),

          // Bundle cards
          SizedBox(
            height: height * 0.34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              itemCount: controller.bundleList.length,
              itemBuilder: (context, index) {
                final BundleModel bundle = controller.bundleList[index];
                return _BundleCard(
                  bundle: bundle,
                  width: width,
                  controller: controller,
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

// ── Bundle card ────────────────────────────────────────────────────
class _BundleCard extends StatelessWidget {
  final BundleModel bundle;
  final double width;
  final BundleController controller;

  const _BundleCard({
    required this.bundle,
    required this.width,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount =
        bundle.discountPercent > 0 && bundle.originalPrice > bundle.bundlePrice;
    final int discountPct = bundle.discountPercent.round();
    final int itemCount = bundle.products.length;
    final String resolvedImageUrl = _resolveImageUrl(bundle.image);

    return Container(
      width: width * 0.42,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image block ────────────────────────────────
          Expanded(
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
                  child: resolvedImageUrl.isNotEmpty
                      ? Image.network(
                          resolvedImageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, _) {
                            // Surfaces the real cause in debug console
                            // instead of silently showing a placeholder.
                            debugPrint(
                              'Bundle image failed to load: '
                              '$resolvedImageUrl ($error)',
                            );
                            return Icon(
                              Icons.card_giftcard,
                              color: Colors.grey[300],
                              size: 36,
                            );
                          },
                        )
                      : Icon(
                          Icons.card_giftcard,
                          color: Colors.grey[300],
                          size: 36,
                        ),
                ),

                // Discount badge (top-left)
                if (hasDiscount)
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
                        "-$discountPct%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),

                // Item count badge (top-right)
                if (itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$itemCount items",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info block ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Full-width ADD button ────────────────
                GestureDetector(
                  onTap: () async {
                    await controller.addBundleToCart(bundle);
                    Get.to(() => const CartPage());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.green.shade600,
                        width: 1.2,
                      ),
                    ),
                    child: const Text(
                      "ADD",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  bundle.name,
                  textAlign: TextAlign.start,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${bundle.bundlePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1.5),
                        child: Text(
                          '₹${bundle.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
