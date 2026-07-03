import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/models/product_model.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

// ── Design tokens ─────────────────────────────────────────────────
const _kPrimary = Color(0xFF1DB954); // vivid green
const _kPrimaryDark = Color(0xFF0F8C3A); // deep green
const _kSurface = Color(0xFFF6F8F5); // off-white with green tint
const _kCard = Colors.white;
const _kTextPrimary = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kOutOfStock = Color(0xFFFF4D4D);
const _kBadgeBg = Color(0xFFE8F5EC);

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage>
    with SingleTickerProviderStateMixin {
  late ProductController productController;
  bool isSearch = false;

  final CategoryController categoryController = Get.put(CategoryController());
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  var selectedCategoryId = "all".obs;
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args['isSearch'] == true) {
      isSearch = true;
      productController = Get.find<ProductController>(tag: "search");
    } else {
      productController = Get.find<ProductController>(tag: "all");
      productController.fetchProducts();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSearch && Get.arguments != null) {
        final all = Get.arguments['results'];
        productController.productList.assignAll(all);
      }
    });

    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
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
            // ── Search bar ──────────────────────────────────────
            SliverToBoxAdapter(child: _buildSearchBar()),

            // ── Category chips ──────────────────────────────────
            SliverToBoxAdapter(child: _buildCategoryChips()),

            // ── Result count label ──────────────────────────────
            SliverToBoxAdapter(
              child: Obx(
                () => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    "${productController.productList.length} products",
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextMuted,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),

            // ── Product list ────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
              sliver: Obx(
                () => SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = productController.productList[index];
                    return _ProductCard(product: product, index: index);
                  }, childCount: productController.productList.length),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── App bar ────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kPrimary,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      title: const Text(
        "All Products",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 4),
              Obx(() {
                // If cart controller is registered, show count
                try {
                  // fallback safe
                  return const SizedBox.shrink();
                } catch (_) {
                  return const SizedBox.shrink();
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _searchFocused
                  ? _kPrimary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: _searchFocused ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: _searchFocused
                ? _kPrimary.withOpacity(0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: _searchFocused ? _kPrimary : _kTextMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: _doSearch,
                style: const TextStyle(
                  fontSize: 15,
                  color: _kTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: "Search products...",
                  hintStyle: TextStyle(
                    color: _kTextMuted,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _doSearch(searchController.text),
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kPrimary, _kPrimaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Search",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Obx(() {
      final categories = [
        {"id": "all", "name": "All"},
        ...categoryController.categoryList.map(
          (c) => {"id": c.id.toString(), "name": c.name},
        ),
      ];

      return SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selectedCategoryId.value == cat['id'];
            return _CategoryChip(
              label: cat['name']!,
              isSelected: isSelected,
              onTap: () async {
                selectedCategoryId.value = cat['id']!;
                if (isSearch) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
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
                  });
                } else {
                  if (cat['id'] == "all") {
                    await productController.fetchProducts();
                  } else {
                    await productController.fetchProductsByCategory(cat['id']!);
                  }
                }
              },
            );
          },
        ),
      );
    });
  }
}

// ── Category chip ──────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? _kPrimary : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _kTextMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

// ── Product card ───────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final int index;

  const _ProductCard({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = (product.stock ?? 0) == 0;
    final bool isLowStock =
        !isOutOfStock && (product.stock ?? 0) > 0 && (product.stock ?? 0) <= 5;

    final double originalPrice = (product.price as num).toDouble();
    final double discountedPrice = (product.discounted_price as num).toDouble();
    final bool hasDiscount = discountedPrice < originalPrice;
    final int discountPct = hasDiscount
        ? ((1 - discountedPrice / originalPrice) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // ── Left green accent bar ──────────────────────────
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isOutOfStock
                          ? [Colors.grey.shade300, Colors.grey.shade200]
                          : [_kPrimary, _kPrimaryDark],
                    ),
                  ),
                ),
              ),

              // ── Main content ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image container ────────────────────────
                    Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: isOutOfStock
                                ? Colors.grey.shade100
                                : _kBadgeBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Opacity(
                              opacity: isOutOfStock ? 0.4 : 1.0,
                              child: Image.network(
                                product.image,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        // Discount badge
                        if (hasDiscount && !isOutOfStock)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade500,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "-$discountPct%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // ── Info ───────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isOutOfStock
                                  ? Colors.grey.shade400
                                  : _kTextPrimary,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 5),

                          // Unit
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${product.unit_size} ${product.unit_name}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Price row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "₹${discountedPrice.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: isOutOfStock
                                      ? Colors.grey.shade400
                                      : _kPrimaryDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (hasDiscount) ...[
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    "₹${originalPrice.toStringAsFixed(0)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Stock badge
                          _StockBadge(
                            stock: product.stock ?? 0,
                            isOutOfStock: isOutOfStock,
                            isLowStock: isLowStock,
                          ),
                        ],
                      ),
                    ),

                    // ── Arrow ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: isOutOfStock
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
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
  }
}

// ── Stock badge ────────────────────────────────────────────────────
class _StockBadge extends StatelessWidget {
  final int stock;
  final bool isOutOfStock;
  final bool isLowStock;

  const _StockBadge({
    required this.stock,
    required this.isOutOfStock,
    required this.isLowStock,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.remove_shopping_cart_rounded,
              size: 12,
              color: Colors.red.shade400,
            ),
            const SizedBox(width: 5),
            Text(
              "Out of Stock",
              style: TextStyle(
                color: Colors.red.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 12,
              color: Colors.orange.shade600,
            ),
            const SizedBox(width: 5),
            Text(
              "Only $stock left",
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kBadgeBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: _kPrimary),
          const SizedBox(width: 5),
          Text(
            "In Stock",
            style: const TextStyle(
              color: _kPrimaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
