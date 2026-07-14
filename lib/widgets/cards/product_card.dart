// ── Compact product card used inside curated category sections ──────
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';

class PromoProductCard extends StatelessWidget {
  final dynamic product;
  final WishlistController wishlistController;

  const PromoProductCard({
    super.key,
    required this.product,
    required this.wishlistController,
  });

  @override
  Widget build(BuildContext context) {
    final double price = (product.price as num).toDouble();

    // discounted_price may not exist on every product model — fall back
    // safely to the regular price if it's missing.
    double discountedPrice = price;
    try {
      final dynamic dp = (product as dynamic).discounted_price;
      if (dp != null) discountedPrice = (dp as num).toDouble();
    } catch (_) {
      // field doesn't exist — keep discountedPrice == price
    }

    final bool hasDiscount = discountedPrice < price;
    final int discountPct = hasDiscount
        ? ((1 - discountedPrice / price) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image block ────────────────────────────────
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
                    child: Image.network(
                      product.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[300],
                      ),
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

                  // Wishlist heart (top-right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Obx(
                      () => GestureDetector(
                        onTap: () => wishlistController.toggle(product),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            wishlistController.isWishlisted(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 12,
                            color: wishlistController.isWishlisted(product.id)
                                ? const Color(0xFFE0386A)
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ADD button (bottom-right, overlapping image)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        Get.to(() => ProductDetailsPage(product: product));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.green.shade600,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          "VIEW",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info block ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
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
    );
  }
}
