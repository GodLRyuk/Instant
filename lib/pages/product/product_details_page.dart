import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import 'package:instant_delivery/pages/cart/checkout_page.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class ProductDetailsPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartController cartController = Get.put(CartController());
  final ScrollController _scrollController = ScrollController();
  late ProductController productController;

  late ProductController recommendedController;
  late ProductController newArrivalController;

  RxInt quantity = 1.obs;
  Rx<dynamic> currentProduct = Rx(null);
  final ProductController controller = Get.find();
  RxDouble averageRating = 0.0.obs;
  RxInt reviewCount = 0.obs;
  @override
  void initState() {
    super.initState();

    currentProduct.value = widget.product;
    controller.loadProductReviews(widget.product.id);

    /// Recommended
    if (Get.isRegistered<ProductController>(tag: "rec")) {
      recommendedController = Get.find(tag: "rec");
    } else {
      recommendedController = Get.put(ProductController(), tag: "rec");
      recommendedController.fetchRecommended();
    }

    /// New Arrival
    if (Get.isRegistered<ProductController>(tag: "new")) {
      newArrivalController = Get.find(tag: "new");
    } else {
      newArrivalController = Get.put(ProductController(), tag: "new");
      newArrivalController.fetchNewArrivals();
    }

    /// ✅ FIX HERE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool isInCart(int productId) {
    return cartController.cartItems.any((item) => item.product_id == productId);
  }

  Future<void> showFullWidthLoader(dynamic product) async {
    showDialog(
      context: context,
      barrierColor: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
      barrierDismissible: false,
      builder: (context) {
        return const SizedBox.expand(
          child: ColoredBox(
            color: Color.fromARGB(
              135,
              255,
              255,
              255,
            ), // semi-transparent overlay
            child: Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 0, 0, 0),
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
    await Future.delayed(const Duration(seconds: 3));
    Navigator.of(context).pop();

    // Update main product
    currentProduct.value = null;

    await Future.delayed(const Duration(milliseconds: 100));

    currentProduct.value = product;
    quantity.value = 1;

    // Scroll to top
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Instant",
        isTransparent: false,
        showBackButton: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Obx(() {
        if (currentProduct.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final product = currentProduct.value;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.25, 0),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _buildContent(product),
        );
      }),
    );
  }

  Widget _buildContent(dynamic product) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    int stock = product.stock ?? 0;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE
          Stack(
            children: [
              Container(
                height: height * 0.4,
                width: double.infinity,
                color: Colors.white,
                child: Image.network(product.image, fit: BoxFit.contain),
              ),
            ],
          ),

          SizedBox(height: height * 0.015),

          /// PRODUCT INFO
          Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: width * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Obx(() {
                  return Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${controller.averageRating.value.toStringAsFixed(1)} (${controller.reviewCount.value} reviews)",
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 10),

                /// PRICE
                Row(
                  children: [
                    Text(
                      "₹${product.discounted_price}",
                      style: TextStyle(
                        fontSize: width * 0.05,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${product.price}",
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${product.discount_percent} %",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.015),

          /// UNIT
          Container(
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                const Text(
                  "Unit: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "${product.unit_size ?? ''} ${product.unit_name ?? ''}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.015),
          Container(
            width: double.infinity, // 👈 ensures full width
            margin: EdgeInsets.symmetric(horizontal: width * 0.04),
            padding: EdgeInsets.all(width * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // 👈 important
              children: [
                const Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  product.description ?? "No description available",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          SizedBox(height: height * 0.015),

          /// QUANTITY
          stock == 0
              ? const Center(
                  child: Text(
                    "Out of Stock",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                  padding: EdgeInsets.all(width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Quantity",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              if (quantity.value > 1) quantity.value--;
                            },
                            icon: const Icon(Icons.remove),
                          ),
                          Text(quantity.value.toString()),
                          IconButton(
                            onPressed: () {
                              if (quantity.value < stock) quantity.value++;
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

          SizedBox(height: height * 0.015),

          /// BUTTONS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            child: Row(
              children: [
                Expanded(
                  child: Obx(() {
                    final added = isInCart(product.id);
                    return GestureDetector(
                      onTap: () async {
                        if (added) {
                          Get.to(() => CartPage());
                        } else {
                          await cartController.addToCart(
                            product.id,
                            quantity.value,
                          );
                          await cartController.fetchCart();
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: added ? Colors.orange : Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            added ? "Go to Cart" : "Add to Cart",
                            style: TextStyle(
                              color: added ? Colors.white : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      // Go to checkout instead of cart
                      Get.to(
                        () => CheckoutPage(
                          totalAmount:
                              product.discounted_price * quantity.value,
                          items: [
                            {
                              "product": product.id,
                              "name": product.name,
                              "price": product.discounted_price,
                              "quantity": quantity.value,
                              "image": product.image,
                            },
                          ],
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Buy Now",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: height * 0.02),
          SizedBox(height: height * 0.015),

          _buildReviewsSection(product.id), // 🔥 ADD THIS

          SizedBox(height: height * 0.02),

          /// RECOMMENDED
          if (recommendedController.recommendedList.isNotEmpty) ...[
            _buildHorizontalList(
              "Recommended for you",
              recommendedController.recommendedList,
              "rec",
            ),
          ],

          SizedBox(height: height * 0.015),

          /// NEW ARRIVAL
          _buildHorizontalList(
            "New Arrival",
            newArrivalController.newArrivalList,
            "new",
          ),
        ],
      ),
    );
  }

  /// 🔥 Horizontal product list builder
  Widget _buildHorizontalList(String title, List list, String tag) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    ProductController controller = tag == "rec"
        ? recommendedController
        : newArrivalController;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.to(() => AllProductsPage()),
                child: const Text("View All"),
              ),
            ],
          ),
        ),
        SizedBox(height: height * 0.015),
        SizedBox(
          height: height * 0.28,
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (list.isEmpty) {
              return const Center(child: Text("No products found"));
            }

            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return GestureDetector(
                  onTap: () async {
                    currentProduct.value = null;

                    await this.controller.loadProductReviews(item.id);

                    currentProduct.value = item;

                    quantity.value = 1;

                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: width * 0.42,
                    margin: EdgeInsets.only(
                      left: width * 0.04,
                      bottom: height * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item.image,
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.03,
                            vertical: height * 0.005,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: height * 0.004),
                              Text(
                                "₹${item.price}",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.035,
                                ),
                              ),
                              SizedBox(height: height * 0.008),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: height * 0.007,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green,
                                        Colors.green.shade700,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "View",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(dynamic product) {
    return Obx(() {
      final reviews = controller.reviews;
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              "Reviews (${reviews.length})",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            /// AVERAGE RATING (from product)
            Row(
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 20),
                const SizedBox(width: 5),
                Text(
                  "${controller.averageRating.value.toStringAsFixed(1)} / 5",
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// REVIEWS LIST
            reviews.isEmpty
                ? const Text(
                    "No reviews yet",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = reviews[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// AVATAR
                            CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                (r['user_name'] ?? "U")[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),

                            const SizedBox(width: 10),

                            /// CONTENT
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// USER NAME
                                  Text(
                                    r['user_name'] ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  /// COMMENT
                                  Text(
                                    r['comment'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// RATING
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                                const SizedBox(width: 3),
                                Text("${r['rating']}"),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      );
    });
  }
}
