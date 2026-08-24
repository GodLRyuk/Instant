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
const _kTextPrimary = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);
const _kDiscountBlue = Color(0xFF1D8FE1);
const _kStar = Color(0xFFFFB800);
const _kGroupBg = Color(0xFFF3FBF6); // light green bg for selected left tab

// ── Filter model ───────────────────────────────────────────────────
// Generic option/group structure so the sheet works for any filter
// facet (price, type, food type, properties, taste profile, ...).
// Wire `count` and `value` to real data once your ProductController
// exposes faceted counts; until then these are illustrative.
class _FilterOption {
  final String label;
  final String value;
  final int? count;
  const _FilterOption(this.label, this.value, {this.count});
}

class _FilterGroup {
  final String name;
  final List<_FilterOption> options;
  const _FilterGroup(this.name, this.options);
}

const List<_FilterOption> _kPriceOptions = [
  _FilterOption("Below ₹99", "0-99"),
  _FilterOption("₹100 - ₹199", "100-199"),
  _FilterOption("₹200 - ₹499", "200-499"),
  _FilterOption("Above ₹500", "500+"),
];

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

  // group name -> set of selected option values.
  // NOTE: each group is now radio-style (max 1 value per group) —
  // enforced in _FilterSheetState's tap handler, not here.
  var selectedFilterValues = <String, Set<String>>{}.obs;

  // Category/search-scoped product list *before* facet filters (Price,
  // ...) are applied on top of it. productController.productList
  // is what the grid actually renders, so it always holds the final,
  // fully-filtered result.
  final RxList<dynamic> _baseProducts = <dynamic>[].obs;

  int get _activeFilterCount =>
      selectedFilterValues.values.fold(0, (sum, s) => sum + s.length);

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args != null && args['isSearch'] == true) {
      isSearch = true;
      productController = Get.find<ProductController>(tag: "search");
    } else {
      productController = Get.find<ProductController>(tag: "all");
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await productController.fetchProducts();
        _baseProducts.assignAll(productController.productList);
        _applyFacetFilters();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSearch && Get.arguments != null) {
        final all = Get.arguments['results'];
        productController.productList.assignAll(all);
        _baseProducts.assignAll(all);
        _applyFacetFilters();
      }
    });
  }

  // ── Category loading (re-establishes _baseProducts, then re-applies
  // whatever facet filters are currently selected — e.g. Price) ─────
  Future<void> _loadCategoryProducts(String id) async {
    if (isSearch) {
      final all = Get.arguments?['results'] ?? [];
      if (id == "all") {
        _baseProducts.assignAll(all);
      } else {
        _baseProducts.assignAll(
          all.where((p) => p.category.toString() == id).toList(),
        );
      }
    } else {
      if (id == "all") {
        await productController.fetchProducts();
      } else {
        await productController.fetchProductsByCategory(id);
      }
      _baseProducts.assignAll(productController.productList);
    }
    _applyFacetFilters();
  }

  // ── Facet filtering — Categories is now handled by
  // _loadCategoryProducts (real fetch, since each group is
  // single-pick). This only applies the remaining facets (Price, and
  // any future non-category facet) on top of whatever _baseProducts
  // currently holds. Wrapped defensively so a bad filter/field never
  // blanks the whole grid — worst case, falls back to unfiltered list.
  void _applyFacetFilters() {
    try {
      Iterable<dynamic> filtered = _baseProducts;

      selectedFilterValues.forEach((groupName, values) {
        if (values.isEmpty) return;
        if (groupName == "Price") {
          filtered = filtered.where((p) => _matchesPriceRange(p, values));
        }
        // Categories intentionally NOT filtered here — it's applied via
        // _loadCategoryProducts as a real network-scoped fetch instead.
      });

      productController.productList.assignAll(
        filtered.cast<ProductModel>().toList(),
      );
    } catch (e, st) {
      debugPrint("Facet filter failed, showing unfiltered list: $e\n$st");
      productController.productList.assignAll(
        _baseProducts.cast<ProductModel>().toList(),
      );
    }
  }

  bool _matchesPriceRange(dynamic product, Set<String> ranges) {
    double price;
    try {
      price = (product.discounted_price as num).toDouble();
    } catch (_) {
      return true; // can't determine price — don't hide the product
    }
    for (final r in ranges) {
      switch (r) {
        case "0-99":
          if (price < 100) return true;
          break;
        case "100-199":
          if (price >= 100 && price < 200) return true;
          break;
        case "200-499":
          if (price >= 200 && price < 500) return true;
          break;
        case "500+":
          if (price >= 500) return true;
          break;
      }
    }
    return false;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
            Obx(() {
              if (productController.productList.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
                sliver: SliverGrid(
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
              );
            }),

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
            // "Filters" chip → opens the half-screen filter sheet.
            _filterChip(
              label: _activeFilterCount > 0
                  ? "Filters ($_activeFilterCount)"
                  : "Filters",
              icon: Icons.tune_rounded,
              isSelected: _activeFilterCount > 0,
              onTap: _openFilterSheet,
            ),

            // Divider between the Filters chip and categories
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              width: 1,
              color: _kBorder,
            ),

            // Category chips (unchanged behaviour)
            ...categories.map((cat) {
              final isSelected = selectedCategoryId.value == cat['id'];
              return _filterChip(
                label: cat['name']!,
                isSelected: isSelected,
                onTap: () async {
                  selectedCategoryId.value = cat['id']!;

                  // The chip is now the source of truth for category —
                  // keep the Filters-sheet Categories selection in sync
                  // so the sheet doesn't show a stale radio pick.
                  final updated = Map<String, Set<String>>.from(
                    selectedFilterValues,
                  );
                  if (cat['id'] == "all") {
                    updated.remove("Categories");
                  } else {
                    updated["Categories"] = {cat['id']!};
                  }
                  selectedFilterValues.value = updated;

                  await _loadCategoryProducts(cat['id']!);
                },
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _filterChip({
    Key? key,
    required String label,
    IconData? icon,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: GestureDetector(
        key: key,
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

  Widget _buildEmptyState() {
    final bool hasActiveFilters = _activeFilterCount > 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              hasActiveFilters
                  ? "No products match your filters"
                  : "No products found",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 6),
              const Text(
                "Try removing a filter to see more results.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _kTextMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  selectedFilterValues.value = {};
                  selectedCategoryId.value = "all";
                  await _loadCategoryProducts("all");
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Clear Filters",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Half-screen Filters sheet ────────────────────────────────────
  List<_FilterGroup> _buildFilterGroups() {
    return [
      const _FilterGroup("Price", _kPriceOptions),
      _FilterGroup(
        "Categories",
        categoryController.categoryList
            .map((c) => _FilterOption(c.name, c.id.toString()))
            .toList(),
      ),
    ];
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<Map<String, Set<String>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterSheet(
        groups: _buildFilterGroups(),
        initialSelections: selectedFilterValues.map(
          (k, v) => MapEntry(k, Set<String>.from(v)),
        ),
      ),
    );

    if (result == null) return;

    selectedFilterValues.value = result;

    // Each group is radio-style now (max 1 value), so Categories is
    // just 0 or 1 pick. Reuse the real fetch path instead of a local
    // (and easily-mismatched) client-side facet match.
    final catSel = result["Categories"] ?? {};
    final newCategoryId = catSel.isEmpty ? "all" : catSel.first;
    selectedCategoryId.value = newCategoryId;

    await _loadCategoryProducts(newCategoryId);
  }
}

// ── Filter bottom sheet content ──────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final List<_FilterGroup> groups;
  final Map<String, Set<String>> initialSelections;

  const _FilterSheet({required this.groups, required this.initialSelections});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late int _activeGroupIndex;
  late Map<String, Set<String>> _selections;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _activeGroupIndex = 0;
    _selections = {
      for (final g in widget.groups)
        g.name: {...?widget.initialSelections[g.name]},
    };
  }

  int get _totalSelected =>
      _selections.values.fold(0, (sum, s) => sum + s.length);

  @override
  Widget build(BuildContext context) {
    final activeGroup = widget.groups[_activeGroupIndex];
    final visibleOptions = _query.isEmpty
        ? activeGroup.options
        : activeGroup.options
              .where(
                (o) => o.label.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 14),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Filters",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1F2937),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: "Search across filters...",
                    hintStyle: const TextStyle(
                      color: _kTextMuted,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: _kTextMuted,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _kPrimary),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Body: left group nav + right options
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left nav
                    SizedBox(
                      width: 118,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: widget.groups.length,
                        itemBuilder: (context, index) {
                          final group = widget.groups[index];
                          final isActive = index == _activeGroupIndex;
                          final count = _selections[group.name]?.length ?? 0;

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _activeGroupIndex = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? _kGroupBg
                                    : Colors.transparent,
                                border: Border(
                                  left: BorderSide(
                                    color: isActive
                                        ? _kPrimary
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isActive
                                            ? _kPrimaryDark
                                            : _kTextPrimary,
                                      ),
                                    ),
                                  ),
                                  if (count > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _kPrimary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "$count",
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Divider
                    Container(width: 1, color: _kBorder),

                    // Right options
                    Expanded(
                      child: visibleOptions.isEmpty
                          ? const Center(
                              child: Text(
                                "No filters found",
                                style: TextStyle(
                                  color: _kTextMuted,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount: visibleOptions.length,
                              itemBuilder: (context, index) {
                                final option = visibleOptions[index];
                                final isChecked =
                                    _selections[activeGroup.name]?.contains(
                                      option.value,
                                    ) ??
                                    false;

                                return InkWell(
                                  // Radio behavior: picking a new option in
                                  // this group clears any other selection in
                                  // the SAME group first. Tapping the
                                  // already-selected option deselects it.
                                  onTap: () => setState(() {
                                    final set = _selections[activeGroup.name]!;
                                    if (isChecked) {
                                      set.clear();
                                    } else {
                                      set
                                        ..clear()
                                        ..add(option.value);
                                    }
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          option.count != null
                                              ? "${option.label} (${option.count})"
                                              : option.label,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _kTextPrimary,
                                          ),
                                        ),
                                        // Radio circle (was a checkbox square)
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                            border: Border.all(
                                              color: isChecked
                                                  ? _kPrimary
                                                  : _kBorder,
                                              width: 1.4,
                                            ),
                                          ),
                                          child: isChecked
                                              ? Center(
                                                  child: Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: _kPrimary,
                                                        ),
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _totalSelected == 0
                            ? null
                            : () => setState(() {
                                for (final k in _selections.keys) {
                                  _selections[k]!.clear();
                                }
                              }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _kPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Clear Filter",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _totalSelected == 0
                                ? _kPrimary.withValues(alpha: 0.4)
                                : _kPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(_selections),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Apply",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

    final double rating = (_tryGet(product, 'rating') as num?)?.toDouble() ?? 0;
    final int reviewCount =
        (_tryGet(product, 'reviewCount') as num?)?.toInt() ?? 0;
    final String deliveryTime =
        (_tryGet(product, 'deliveryTime') as String?) ?? "15-30 mins";

    return GestureDetector(
      onTap: () => Get.to(() => ProductDetailsPage(product: product)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                                : _kTextMuted.withValues(alpha: 0.3),
                          ),
                        );
                      }),
                    ),
                  ),
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
