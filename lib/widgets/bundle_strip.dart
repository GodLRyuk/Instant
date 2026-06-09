import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import '../controllers/bundle_controller.dart';

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
            height: height * 0.28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.bundleList.length,
              itemBuilder: (context, index) {
                final bundle = controller.bundleList[index];

                return Container(
                  width: width * 0.72,
                  margin: EdgeInsets.only(
                    left: width * 0.04,
                    right: index == controller.bundleList.length - 1
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
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Bundle name + discount badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                bundle.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '-${bundle.discountPercent.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: height * 0.005),

                        // Description
                        Text(
                          bundle.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: width * 0.03,
                            color: Colors.grey[600],
                          ),
                        ),

                        SizedBox(height: height * 0.01),

                        // Product images row
                        SizedBox(
                          height: height * 0.09,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: bundle.products.length,
                            itemBuilder: (context, i) {
                              final product = bundle.products[i];
                              return Container(
                                width: height * 0.09,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.image.isNotEmpty
                                      ? Image.network(
                                          product.image,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                              ),
                                        )
                                      : const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(height: height * 0.01),

                        // Price row + Add button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹${bundle.bundlePrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: width * 0.045,
                                  ),
                                ),
                                Text(
                                  '₹${(bundle.originalPrice).toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: width * 0.03,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () async {
                                await controller.addBundleToCart(bundle);
                                Get.to(() => const CartPage());
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.06,
                                  vertical: height * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(
                                    width * 0.02,
                                  ),
                                ),
                                child: Text(
                                  'Add To Cart',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.033,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
