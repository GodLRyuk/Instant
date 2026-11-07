// ── Compact product card used inside curated category sections ──────
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final double price = (product.price as num).toDouble();

    double discountedPrice = price;
    try {
      final dynamic dp = (product as dynamic).discounted_price;
      if (dp != null) discountedPrice = (dp as num).toDouble();
    } catch (_) {}

    final bool hasDiscount = discountedPrice < price;
    final int discountPct = hasDiscount
        ? ((1 - discountedPrice / price) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailsPage(product: product),
        preventDuplicates: false,
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF6F8F5),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      placeholder: (_, _) =>
                          Icon(Icons.image, color: Colors.grey[300]),
                      errorWidget: (_, _, _) => Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.012,
                          vertical: screenWidth * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade500,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "-$discountPct%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 360 ? 8 : 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Obx(
                      () => GestureDetector(
                        onTap: () => wishlistController.toggle(product),
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.01),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            wishlistController.isWishlisted(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: screenWidth < 360 ? 11 : 12,
                            color: wishlistController.isWishlisted(product.id)
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
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 0),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.022,
                  screenWidth * 0.012,
                  screenWidth * 0.022,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(
                        () => ProductDetailsPage(product: product),
                        preventDuplicates: false,
                        transition: Transition.fadeIn,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "VIEW",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth < 360 ? 1 : 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '₹${discountedPrice.toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 10 : 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (hasDiscount) ...[
                          SizedBox(width: screenWidth < 360 ? 1 : 2),
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 0.5),
                              child: Text(
                                '₹${price.toStringAsFixed(0)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 8.5 : 9.5,
                                  color: Colors.red.shade400,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 1),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: screenWidth < 360 ? 8.5 : 9.5,
                        fontWeight: FontWeight.w600,
                        height: 1.05,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
