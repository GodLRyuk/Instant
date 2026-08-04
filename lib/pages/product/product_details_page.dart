import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import 'package:instant_delivery/pages/cart/checkout_page.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/widgets/branding/branding.dart';
import 'package:instant_delivery/widgets/cards/category_card.dart';
import 'package:instant_delivery/widgets/cards/product_card.dart';
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
  final CategoryController categoryController = Get.put(CategoryController());
  RxInt quantity = 1.obs;
  Rx<dynamic> currentProduct = Rx(null);
  final ProductController controller = Get.find();
  RxDouble averageRating = 0.0.obs;
  RxInt reviewCount = 0.obs;
  final WishlistController wishlistController = Get.put(WishlistController());

  // Tracks whether the "Add to Cart" API call is currently in flight,
  // so we can show a loading spinner and prevent duplicate taps.
  final RxBool isAddingToCart = false.obs;

  // Tracks whether the "Buy Now" flow is currently preparing (waiting on
  // delivery slots to be ready) before opening the schedule sheet.
  final RxBool isBuyNowLoading = false.obs;

  // ── Scheduling state (for Buy Now bottom sheet) ───────────────
  String _deliveryType = 'ASAP';
  List<dynamic> _slotDays = [];
  bool _slotsLoading = true;
  int _selectedDayIndex = 0;
  String? _selectedSlotStart;
  String? _selectedSlotEnd;

  // Future for the initial slots fetch, so "Buy Now" can await it if the
  // user taps before slots have finished loading. Initialized eagerly
  // (not `late`) so it's always safe to await even if initState hasn't
  // run yet on this instance (e.g. right after a hot reload).
  Future<void> _slotsFuture = Future.value();

  @override
  void initState() {
    super.initState();
    currentProduct.value = widget.product;
    controller.loadProductReviews(widget.product.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadProductReviews(widget.product.id);
    });

    _slotsFuture = _fetchSlots();

    if (Get.isRegistered<ProductController>(tag: "rec")) {
      recommendedController = Get.find(tag: "rec");
    } else {
      recommendedController = Get.put(ProductController(), tag: "rec");
      recommendedController.fetchRecommended();
    }

    if (Get.isRegistered<ProductController>(tag: "new")) {
      newArrivalController = Get.find(tag: "new");
    } else {
      newArrivalController = Get.put(ProductController(), tag: "new");
      newArrivalController.fetchNewArrivals();
    }

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

  // ── Slot helpers ──────────────────────────────────────────────
  Future<void> _fetchSlots() async {
    try {
      final slots = await ApiService().getDeliverySlots();
      setState(() {
        _slotDays = slots;
        _slotsLoading = false;
      });
    } catch (_) {
      setState(() => _slotsLoading = false);
    }
  }

  String _formatSlotTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  List<dynamic> get _currentSlots =>
      _slotDays.isEmpty ? [] : (_slotDays[_selectedDayIndex]['slots'] ?? []);

  String? _toBackendTime(String? t) {
    if (t == null) return null;
    if (!t.contains('AM') && !t.contains('PM')) {
      return t.length == 5 ? '$t:00' : t;
    }
    final parts = t.split(' ');
    final tp = parts[0].split(':');
    int h = int.parse(tp[0]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return '${h.toString().padLeft(2, '0')}:${tp[1]}:00';
  }

  // ── Buy Now bottom sheet ──────────────────────────────────────
  void _showBuyNowSheet(dynamic product) {
    // Reset state each time sheet opens
    setState(() {
      _deliveryType = 'ASAP';
      _selectedSlotStart = null;
      _selectedSlotEnd = null;
      _selectedDayIndex = 0;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuyNowScheduleSheet(
        product: product,
        quantity: quantity.value,
        slotDays: _slotDays,
        slotsLoading: _slotsLoading,
        formatSlotTime: _formatSlotTime,
        toBackendTime: _toBackendTime,
        onConfirm: (scheduleData) {
          Navigator.pop(context);
          final items = [
            {
              "product": product.id,
              "name": product.name,
              "price": product.discounted_price,
              "quantity": quantity.value,
              "image": product.image,
            },
          ];
          Get.to(
            () => CheckoutPage(
              totalAmount:
                  (product.discounted_price as num).toDouble() * quantity.value,
              items: items,
              appliedCouponCode: '',
              discountAmount: 0.0,
              deliveryType: scheduleData['deliveryType'] ?? 'ASAP',
              scheduledDate: scheduleData['scheduledDate'],
              scheduledSlotStart: scheduleData['scheduledSlotStart'],
              scheduledSlotEnd: scheduleData['scheduledSlotEnd'],
            ),
          );
        },
      ),
    );
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
            color: Color.fromARGB(135, 255, 255, 255),
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

    currentProduct.value = null;
    await Future.delayed(const Duration(milliseconds: 100));
    currentProduct.value = product;
    quantity.value = 1;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // ── Build ─────────────────────────────────────────────────────
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
      child: Stack(
        children: [
          Column(
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
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 18,
                          ),
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

              /// DESCRIPTION
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Description",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
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
                          Obx(
                            () => Row(
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
                                    if (quantity.value < stock) {
                                      quantity.value++;
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
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
                    // Add to Cart / Go to Cart
                    Expanded(
                      child: Obx(() {
                        final added = isInCart(product.id);
                        final outOfStock = (product.stock ?? 0) == 0;
                        final isLoading = isAddingToCart.value;

                        return GestureDetector(
                          onTap: () async {
                            if (outOfStock || isLoading) {
                              // do nothing if out of stock or a request
                              // is already in flight
                              return;
                            }

                            if (added) {
                              Get.to(() => CartPage());
                            } else {
                              isAddingToCart.value = true;
                              try {
                                // ✅ Only update button state and cart if API returns 200
                                final success = await cartController.addToCart(
                                  product.id,
                                  quantity.value,
                                );
                                if (success) {
                                  await cartController
                                      .fetchCart(); // refresh cart list so isInCart() becomes true
                                }
                                // If success == false: snackbar already shown by controller,
                                // button stays green "Add to Cart", no state change.
                              } finally {
                                // Always clear the loading state, whether
                                // the call succeeded, failed, or threw.
                                isAddingToCart.value = false;
                              }
                            }
                          },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              // Only show orange "Go to Cart" colour when actually in cart AND has stock
                              color: added && !outOfStock
                                  ? Colors.orange
                                  : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.green,
                                      ),
                                    )
                                  : Text(
                                      outOfStock
                                          ? "Out of Stock"
                                          : added
                                          ? "Go to Cart"
                                          : "Add to Cart",
                                      style: TextStyle(
                                        color: outOfStock
                                            ? Colors.grey
                                            : added
                                            ? Colors.white
                                            : Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 10),
                    // Buy Now — opens scheduling bottom sheet
                    Expanded(
                      child: Obx(() {
                        final outOfStock = (product.stock ?? 0) == 0;
                        final isLoading = isBuyNowLoading.value;

                        return GestureDetector(
                          onTap: outOfStock
                              ? null
                              : () async {
                                  if (isLoading) {
                                    // already preparing — ignore extra taps
                                    return;
                                  }
                                  isBuyNowLoading.value = true;
                                  try {
                                    // Make sure delivery slots have finished
                                    // loading before showing the sheet.
                                    await _slotsFuture;
                                  } finally {
                                    isBuyNowLoading.value = false;
                                  }
                                  _showBuyNowSheet(product);
                                },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: outOfStock
                                  ? null
                                  : LinearGradient(
                                      colors: [
                                        Colors.green,
                                        Colors.green.shade700,
                                      ],
                                    ),
                              color: outOfStock ? Colors.grey.shade300 : null,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Buy Now",
                                      style: TextStyle(
                                        color: outOfStock
                                            ? Colors.grey.shade500
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.02),

              _buildReviewsSection(product.id),

              /// RECOMMENDED
              SizedBox(height: height * 0.015),
              if (recommendedController.recommendedList.isNotEmpty) ...[
                SectionHeader(
                  title: 'Recommended for you',
                  onViewAll: () => Get.to(() => AllProductsPage()),
                ),

                SizedBox(height: height * 0.015),

                // 🔥 Horizontal Product List (Different Design)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Obx(() {
                    if (recommendedController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final recommended = recommendedController.recommendedList;
                    final displayCount = recommended.length > 6
                        ? 6
                        : recommended.length;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: width * 0.025,
                        mainAxisSpacing: height * 0.015,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) => PromoProductCard(
                        product: recommended[index],
                        wishlistController: wishlistController,
                      ),
                    );
                  }),
                ),
              ],

              /// NEW ARRIVAL
              SizedBox(height: height * 0.015),
              if (newArrivalController.newArrivalList.isNotEmpty) ...[
                SectionHeader(
                  title: 'New Arrival',
                  onViewAll: () => Get.to(() => AllProductsPage()),
                ),

                SizedBox(height: height * 0.015),

                // 🔥 Horizontal Product List (Different Design)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                  child: Obx(() {
                    if (newArrivalController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final newArrivals = newArrivalController.newArrivalList;
                    final displayCount = newArrivals.length > 6
                        ? 6
                        : newArrivals.length;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCount,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: width * 0.025,
                        mainAxisSpacing: height * 0.015,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) => PromoProductCard(
                        product: newArrivals[index],
                        wishlistController: wishlistController,
                      ),
                    );
                  }),
                ),
                SizedBox(height: height * 0.02),
              ],

              AppFooterBranding(),
            ],
          ),

          // Wishlist heart
          Positioned(
            top: 4,
            right: 4,
            child: Obx(
              () => GestureDetector(
                onTap: () => wishlistController.toggle(product),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Icon(
                    wishlistController.isWishlisted(product.id)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 20,
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
    );
  }

  // ── Reviews section ───────────────────────────────────────────
  Widget _buildReviewsSection(dynamic productId) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reviews (${reviews.length})",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showWriteReviewSheet(productId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 15,
                          color: Color(0xFF2E7D32),
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Write a review",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Average rating row ──
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

            // ── Review list ──
            reviews.isEmpty
                ? const Text(
                    "No reviews yet",
                    style: TextStyle(color: Colors.grey),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
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
                            CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(
                                (r['user_name'] ?? "U")[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        r['user_name'] ?? "Unknown",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      _buildStarRow(r['rating'], size: 15),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    r['comment'] ?? "",
                                    style: const TextStyle(
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildStarRow(dynamic rating, {double size = 16}) {
    final int filledStars = (rating is num) ? rating.round().clamp(0, 5) : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < filledStars;
        return Icon(
          isFilled ? Icons.star : Icons.star_border,
          size: size,
          color: isFilled ? Colors.orange : Colors.grey.shade400,
        );
      }),
    );
  }

  void _showWriteReviewSheet(int productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _WriteReviewSheet(productId: productId, controller: controller),
    );
  }
}

// ── Buy Now Schedule Bottom Sheet ─────────────────────────────────
class _BuyNowScheduleSheet extends StatefulWidget {
  final dynamic product;
  final int quantity;
  final List<dynamic> slotDays;
  final bool slotsLoading;
  final String Function(String) formatSlotTime;
  final String? Function(String?) toBackendTime;
  final void Function(Map<String, String?>) onConfirm;

  const _BuyNowScheduleSheet({
    required this.product,
    required this.quantity,
    required this.slotDays,
    required this.slotsLoading,
    required this.formatSlotTime,
    required this.toBackendTime,
    required this.onConfirm,
  });

  @override
  State<_BuyNowScheduleSheet> createState() => _BuyNowScheduleSheetState();
}

class _BuyNowScheduleSheetState extends State<_BuyNowScheduleSheet> {
  String _deliveryType = 'ASAP';
  int _selectedDayIndex = 0;
  String? _selectedSlotStart;
  String? _selectedSlotEnd;

  List<dynamic> get _currentSlots => widget.slotDays.isEmpty
      ? []
      : (widget.slotDays[_selectedDayIndex]['slots'] ?? []);

  bool get _canConfirm =>
      _deliveryType == 'ASAP' ||
      (_selectedSlotStart != null && _selectedSlotEnd != null);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: Color(0xFF3CB549),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Choose Delivery',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Price summary
                    Text(
                      '₹${((widget.product.discounted_price as num) * widget.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── TOGGLE ──
                      Row(
                        children: [
                          _toggleBtn(
                            'ASAP',
                            Icons.bolt,
                            'Instant',
                            '20–30 min',
                          ),
                          const SizedBox(width: 8),
                          _toggleBtn(
                            'SCHEDULED',
                            Icons.calendar_month,
                            'Schedule',
                            'Pick date & time',
                          ),
                        ],
                      ),

                      // ── ASAP INFO ──
                      if (_deliveryType == 'ASAP') ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA5D6A7)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delivery_dining,
                                color: Color(0xFF3CB549),
                                size: 22,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Arriving in 20–30 min',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Estimated based on your location',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF388E3C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // ── SCHEDULED PICKERS ──
                      if (_deliveryType == 'SCHEDULED') ...[
                        const SizedBox(height: 14),
                        if (widget.slotsLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else ...[
                          // Date
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: Color(0xFF3CB549),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Select date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 62,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.slotDays.length,
                              itemBuilder: (_, i) {
                                final day = widget.slotDays[i];
                                final isSelected = _selectedDayIndex == i;
                                final label = day['is_today'] == true
                                    ? 'Today'
                                    : day['day'];
                                final dateNum = (day['date'] as String)
                                    .split('-')
                                    .last;

                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedDayIndex = i;
                                    _selectedSlotStart = null;
                                    _selectedSlotEnd = null;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 52,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFE8F5E9)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFA5D6A7)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          label.toString().substring(0, 3),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isSelected
                                                ? const Color(0xFF2E7D32)
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateNum,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF2E7D32)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Time slots
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF3CB549),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Select time slot',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_currentSlots.where((s) => s['available'] == true).length} available',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 3.2,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                ),
                            itemCount: _currentSlots.length,
                            itemBuilder: (_, i) {
                              final slot = _currentSlots[i];
                              final isAvailable = slot['available'] == true;
                              final slotStart = slot['slot_start'] as String;
                              final slotEnd = slot['slot_end'] as String;
                              final isSelected =
                                  _selectedSlotStart == slotStart;

                              return GestureDetector(
                                onTap: isAvailable
                                    ? () => setState(() {
                                        _selectedSlotStart = slotStart;
                                        _selectedSlotEnd = slotEnd;
                                      })
                                    : null,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE8F5E9)
                                        : isAvailable
                                        ? Colors.white
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFA5D6A7)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.formatSlotTime(slotStart)} – ${widget.formatSlotTime(slotEnd)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : isAvailable
                                          ? Colors.black87
                                          : Colors.grey.shade400,
                                      decoration: isAvailable
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),

              // ── CONFIRM BUTTON ──
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _canConfirm
                        ? () {
                            if (_deliveryType == 'SCHEDULED' &&
                                (_selectedSlotStart == null ||
                                    _selectedSlotEnd == null)) {
                              Get.snackbar(
                                'Select a time slot',
                                'Please pick a date and time slot',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }
                            widget.onConfirm({
                              'deliveryType': _deliveryType,
                              'scheduledDate': _deliveryType == 'SCHEDULED'
                                  ? widget.slotDays[_selectedDayIndex]['date']
                                  : null,
                              'scheduledSlotStart': widget.toBackendTime(
                                _selectedSlotStart,
                              ),
                              'scheduledSlotEnd': widget.toBackendTime(
                                _selectedSlotEnd,
                              ),
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3CB549),
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(
                      _deliveryType == 'ASAP'
                          ? Icons.check_circle_outline
                          : Icons.calendar_month,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      _deliveryType == 'ASAP'
                          ? 'Confirm — Instant delivery'
                          : _selectedSlotStart != null
                          ? 'Confirm — ${widget.slotDays[_selectedDayIndex]['is_today'] == true ? 'Today' : widget.slotDays[_selectedDayIndex]['day']} ${widget.formatSlotTime(_selectedSlotStart!)}'
                          : 'Select a time slot',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toggleBtn(String type, IconData icon, String label, String sub) {
    final isActive = _deliveryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _deliveryType = type;
          _selectedSlotStart = null;
          _selectedSlotEnd = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFFA5D6A7) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? const Color(0xFF388E3C)
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WriteReviewSheet extends StatefulWidget {
  final int productId;
  final ProductController controller;

  const _WriteReviewSheet({required this.productId, required this.controller});

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              "Write a Review",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your rating",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _rating = starValue),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      starValue <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text(
              "Your review",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Share your experience with this product...",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final isSubmitting = widget.controller.isSubmittingReview.value;
              final canSubmit = _rating > 0 && !isSubmitting;

              return SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: canSubmit
                      ? () async {
                          final success = await widget.controller.submitReview(
                            widget.productId,
                            _rating,
                            _commentController.text.trim(),
                          );
                          if (success) {
                            Navigator.pop(context);
                            Get.snackbar(
                              "Thank you!",
                              "Your review has been submitted",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              "Something went wrong",
                              "Please try again",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3CB549),
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Submit Review",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
