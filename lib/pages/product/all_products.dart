import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/models/product_model.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/branding/branding.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

// ── Design tokens ─────────────────────────────────────────────────
const _kPrimary = Color(0xFF1DB954); // vivid green
const _kPrimaryDark = Color(0xFF0F8C3A); // deep green
const _kSurface = Color(0xFFFFFFFF);
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kDiscountBlue = Color(0xFF1D8FE1);
const _kStar = Color(0xFFFFB800);

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  late ProductController productController;
  bool isSearch = false;

  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController searchController = TextEditingController();

  var selectedCategoryId = "all".obs;

  // Simple placeholder brand list for the "Shop by brands" strip.
  // Replace with a real BrandController / API-backed list when available.
  final List<Map<String, String>> _brands = const [
    {"name": "Boldfit", "logo": ""},
    {"name": "Cello", "logo": ""},
    {"name": "Pexpo", "logo": ""},
    {"name": "Milton", "logo": ""},
  ];

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args['isSearch'] == true) {
      isSearch = true;
      productController = Get.find<ProductController>(tag: "search");
    } else {
      productController = Get.find<ProductController>(tag: "all");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        productController.fetchProducts();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSearch && Get.arguments != null) {
        final all = Get.arguments['results'];
        productController.productList.assignAll(all);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String value) async {
    if (value.trim().isEmpty) return;
    final controller = Get.find<ProductController>(tag: "search");
    await controller.filterBySearch(value.trim());
    Get.to(
      () => const AllProductsPage(),
      arguments: {"isSearch": true, "results": controller.productList.toList()},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: CustomAppBar(
        title: "All Products",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimary),
          );
        }
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Filter chip bar ──────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterBar()),

            // ── Product grid ─────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
              sliver: Obx(
                () => SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = productController.productList[index];
                    return _ProductCard(product: product);
                  }, childCount: productController.productList.length),
                ),
              ),
            ),

            // ── Shop by brands ───────────────────────────────────
            // SliverToBoxAdapter(child: _buildBrandsSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      }),
      bottomNavigationBar: const AppFooterBranding(),
    );
  }

  // ── Filter / sort / category chip bar ──────────────────────────
  Widget _buildFilterBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder, width: 1)),
      ),
      child: Obx(() {
        final categories = [
          {"id": "all", "name": "All"},
          ...categoryController.categoryList.map(
            (c) => {"id": c.id.toString(), "name": c.name},
          ),
        ];

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            // Static utility chips
            _filterChip(
              label: "Filters",
              icon: Icons.tune_rounded,
              onTap: () {
                // TODO: open a filter bottom sheet (material, capacity, brand, price, insulation)
              },
            ),
            // Divider between utility chips and categories
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              width: 1,
              color: _kBorder,
            ),

            // Real category chips
            ...categories.map((cat) {
              final isSelected = selectedCategoryId.value == cat['id'];
              return _filterChip(
                label: cat['name']!,
                isSelected: isSelected,
                onTap: () async {
                  selectedCategoryId.value = cat['id']!;
                  if (isSearch) {
                    final all = Get.arguments?['results'] ?? [];
                    if (cat['id'] == "all") {
                      productController.productList.assignAll(all);
                    } else {
                      productController.productList.assignAll(
                        all
                            .where((p) => p.category.toString() == cat['id'])
                            .toList(),
                      );
                    }
                  } else {
                    if (cat['id'] == "all") {
                      await productController.fetchProducts();
                    } else {
                      await productController.fetchProductsByCategory(
                        cat['id']!,
                      );
                    }
                  }
                },
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _filterChip({
    required String label,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary : Colors.white,
            border: Border.all(color: isSelected ? _kPrimary : _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: isSelected ? Colors.white : _kTextPrimary,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : _kTextPrimary,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isSelected ? Colors.white : _kTextMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Shop by brands ──────────────────────────────────────────────
  Widget _buildBrandsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      color: const Color(0xFFF7F3E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Shop by brands",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

// ── Product card (grid style) ───────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final int stock = (product.stock ?? 0) as int;
    final bool isOutOfStock = stock == 0;
    final bool isLowStock = !isOutOfStock && stock <= 5;

    final double originalPrice = (product.price as num).toDouble();
    final double discountedPrice = (product.discounted_price as num).toDouble();
    final bool hasDiscount = discountedPrice < originalPrice;
    final double savedAmount = originalPrice - discountedPrice;
    final int discountPct = hasDiscount
        ? ((1 - discountedPrice / originalPrice) * 100).round()
        : 0;

    // These fields may not exist yet on your ProductModel — fall back safely.
    final double rating = (_tryGet(product, 'rating') as num?)?.toDouble() ?? 0;
    final int reviewCount =
        (_tryGet(product, 'reviewCount') as num?)?.toInt() ?? 0;
    final String deliveryTime =
        (_tryGet(product, 'deliveryTime') as String?) ?? "15 mins";

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image block ──────────────────────────────────────
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Opacity(
                      opacity: isOutOfStock ? 0.4 : 1.0,
                      child: Image.network(product.image, fit: BoxFit.contain),
                    ),
                  ),

                  // Favorite heart
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border_rounded,
                        size: 12,
                        color: _kTextMuted,
                      ),
                    ),
                  ),

                  // Image carousel dots (static placeholder — wire to
                  // a real PageView if the product has multiple images)
                  Positioned(
                    bottom: 28,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0
                                ? _kTextMuted
                                : _kTextMuted.withOpacity(0.3),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Unit size badge (bottom-left)
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Text(
                        "${product.unit_size} ${product.unit_name}",
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                      ),
                    ),
                  ),

                  // VIEW button (bottom-right)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: isOutOfStock
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "VIEW",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => Get.to(
                              () => ProductDetailsPage(product: product),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _kPrimary,
                                  width: 1.2,
                                ),
                              ),
                              child: const Text(
                                "VIEW",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _kPrimaryDark,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Price row ────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${discountedPrice.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isOutOfStock ? Colors.grey.shade400 : _kTextPrimary,
                ),
              ),
              if (hasDiscount) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 1.5),
                  child: Text(
                    "₹${originalPrice.toStringAsFixed(0)}",
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

          if (hasDiscount)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                discountPct > 0 && discountPct < 100
                    ? "$discountPct% OFF"
                    : "₹${savedAmount.toStringAsFixed(0)} OFF",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kDiscountBlue,
                ),
              ),
            ),

          const SizedBox(height: 3),

          // ── Name ─────────────────────────────────────────────
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: isOutOfStock ? Colors.grey.shade400 : _kTextPrimary,
            ),
          ),

          const SizedBox(height: 3),

          // ── Rating ───────────────────────────────────────────
          if (rating > 0)
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 12, color: _kStar),
                const SizedBox(width: 2),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimary,
                  ),
                ),
                if (reviewCount > 0) ...[
                  const SizedBox(width: 3),
                  Text(
                    "$reviewCount",
                    style: const TextStyle(fontSize: 10, color: _kTextMuted),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 2),

          // ── Delivery time + stock ────────────────────────────
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 5,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 11,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    deliveryTime,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 10,
                    color: isOutOfStock
                        ? Colors.red.shade300
                        : isLowStock
                        ? Colors.orange.shade400
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    isOutOfStock ? "Out of stock" : "$stock left",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isOutOfStock
                          ? Colors.red.shade400
                          : isLowStock
                          ? Colors.orange.shade600
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Safe dynamic field access so this compiles even if the field
  // doesn't exist on ProductModel yet — replace with direct field
  // access once you add rating / reviewCount / deliveryTime.
  dynamic _tryGet(dynamic obj, String field) {
    try {
      switch (field) {
        case 'rating':
          return obj.rating;
        case 'reviewCount':
          return obj.reviewCount;
        case 'deliveryTime':
          return obj.deliveryTime;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
