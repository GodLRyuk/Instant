import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/bundle_controller.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/widgets/cards/bundle_strip.dart';
import 'package:instant_delivery/widgets/cards/category_card.dart';
import 'package:instant_delivery/widgets/cards/product_card.dart';
import 'package:instant_delivery/widgets/cards/flash_sale_strip.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryController categoryController = Get.put(CategoryController());

  final ProductController productController = Get.put(
    ProductController(),
    tag: "all",
  );
  final ProductController newArrivalController = Get.put(
    ProductController(),
    tag: "new",
  );
  final ProductController recommendedController = Get.put(
    ProductController(),
    tag: "rec",
  );
  final ProductController searchControllerX = Get.put(
    ProductController(),
    tag: "search",
  );
  late PageController _midBannerController;
  final ProductController bannerController = Get.put(ProductController());
  final ProductController topBannerController = Get.put(ProductController());
  final TextEditingController searchController = TextEditingController();
  final RxList searchResults = [].obs;
  final RxBool showSearchBox = false.obs;
  int _currentPage = 0;
  Timer? _timer;

  final ProductController flashSaleController = Get.put(
    ProductController(),
    tag: "flash",
  );
  final WishlistController wishlistController = Get.put(WishlistController());
  final BundleController bundleController = Get.put(BundleController());

  final List<String> _sectionTitleTemplates = const [
    "{category} temptations await",
    "Discover more {category}",
    "Stock up on {category}",
    "Freshly picked {category}",
    "Top picks in {category}",
    "Everything {category}",
  ];

  final List<String> _sectionSubtitleTemplates = const [
    "Handpicked {category} just for you",
    "Best sellers in {category}",
    "Everything you need in {category}",
    "Loved by our customers",
    "Curated picks, just for you",
  ];

  @override
  void initState() {
    super.initState();

    _midBannerController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });

    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_midBannerController.hasClients &&
          bannerController.bannerList.isNotEmpty) {
        _currentPage++;
        if (_currentPage >= bannerController.bannerList.length) {
          _currentPage = 0;
        }
        _midBannerController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _midBannerController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    await Future.wait<void>([
      categoryController.fetchCategories(),
      productController.fetchProducts(),
      newArrivalController.fetchNewArrivals(),
      recommendedController.fetchRecommended(),
      bannerController.fetchBanners(),
      topBannerController.fetchTopBanners(),
      flashSaleController.fetchFlashSale(),
      bundleController.fetchBundles(),
    ]);
  }

  // 🔥 Icon Mapper
  IconData getIcon(String name) {
    switch (name) {
      case "fastfood":
        return Icons.fastfood;
      case "shopping_cart":
        return Icons.shopping_cart;
      case "apple":
        return Icons.apple;
      case "eco":
        return Icons.eco;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final gridCrossAxisCount = width < 360 ? 2 : 3;
    final gridChildAspectRatio = width < 360
        ? 0.50
        : width < 600
        ? 0.56
        : 0.58;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(title: "Instant", isTransparent: false),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.015),
              Stack(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    // height: height * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        // SizedBox(width: width * 0.03),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: TextField(
                              controller: searchController,
                              textInputAction: TextInputAction.search,

                              // 👇 Keep enter key search
                              onSubmitted: (value) async {
                                await searchControllerX.filterBySearch(value);

                                Get.to(
                                  () => AllProductsPage(),
                                  arguments: {"isSearch": true},
                                );
                              },

                              decoration: InputDecoration(
                                hintText: "Search products...",
                                border: InputBorder.none,

                                // 👇 ADD THIS (right side search icon)
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.search,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () async {
                                    final value = searchController.text.trim();

                                    if (value.isNotEmpty) {
                                      await searchControllerX.filterBySearch(
                                        value,
                                      );

                                      Get.to(
                                        () => AllProductsPage(),
                                        arguments: {"isSearch": true},
                                      );
                                    }
                                  },
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
              SizedBox(height: height * 0.01),
              SizedBox(
                height: height * 0.10,
                child: Obx(() {
                  if (categoryController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categoryController.categoryList.length,
                    itemBuilder: (context, index) {
                      final category = categoryController.categoryList[index];

                      return GestureDetector(
                        onTap: () async {
                          // optional: show loading overlay while fetching all
                          await Future.wait([
                            productController.fetchProductsByCategory(
                              category.id.toString(),
                            ),
                            newArrivalController.fetchNewArrivalsByCategory(
                              category.id.toString(),
                            ),
                            recommendedController.fetchRecommendedByCategory(
                              category.id.toString(),
                            ),
                          ]);
                        },
                        child: Container(
                          width: width * 0.2,
                          margin: EdgeInsets.only(left: width * 0.02),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: width * 0.06,
                                backgroundColor: Colors.green.shade50,
                                child: Image.network(
                                  category.image ?? '',
                                  width: width * 0.08,
                                  height: width * 0.1,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category,
                                      color: Colors.grey[400],
                                      size: width * 0.07,
                                    );
                                  },
                                ),
                              ),
                              // SizedBox(height: height * 0.008),
                              Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: width * 0.03),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              // 🔥 Banner
              Obx(() {
                if (topBannerController.isLoading.value) {
                  return SizedBox(
                    height: height * 0.2,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // Guard against empty list
                if (topBannerController.topbannerList.isEmpty) {
                  return SizedBox(
                    height: height * 0.2,
                  ); // or a placeholder widget
                }

                final banner = topBannerController.topbannerList[0];

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                  height: height * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(width * 0.04),
                    image: DecorationImage(
                      image: NetworkImage(banner.image),
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              }),
              SizedBox(height: height * 0.015),

              FlashSaleStrip(controller: flashSaleController),

              // 🔥 Products Title
              SectionHeader(
                title: 'New Arrival',
                onViewAll: () => Get.to(() => AllProductsPage()),
              ),

              SizedBox(height: height * 0.015),

              // ✅ NEW ARRIVAL — 3-column grid, category-style cards
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Obx(() {
                  if (newArrivalController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final newArrival = newArrivalController.newArrivalList;
                  final displayCount = newArrival.length > 6
                      ? 6
                      : newArrival.length;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayCount,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridCrossAxisCount,
                      crossAxisSpacing: width * 0.025,
                      mainAxisSpacing: height * 0.015,
                      childAspectRatio: gridChildAspectRatio,
                    ),
                    itemBuilder: (context, index) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: const TextScaler.linear(
                          1.0,
                        ), // ignores system font scale
                      ),
                      child: PromoProductCard(
                        product: newArrival[index],
                        wishlistController: wishlistController,
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: height * 0.015),

              const BundleStrip(),

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
                        crossAxisCount: gridCrossAxisCount,
                        crossAxisSpacing: width * 0.025,
                        mainAxisSpacing: height * 0.015,
                        childAspectRatio: gridChildAspectRatio,
                      ),
                      itemBuilder: (context, index) => PromoProductCard(
                        product: recommended[index],
                        wishlistController: wishlistController,
                      ),
                    );
                  }),
                ),
                SizedBox(height: height * 0.02),
              ],
              // 🔥 Sliding Banner
              // 🔥 Sliding Banner
              Obx(() {
                if (bannerController.isLoading.value) {
                  return SizedBox(
                    height: height * 0.18,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                return SizedBox(
                  height: height * 0.20,
                  child: PageView.builder(
                    controller: _midBannerController,
                    itemCount: bannerController.bannerList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final banner = bannerController.bannerList[index];
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(width * 0.04),
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(width * 0.04),
                          child: Image.network(
                            banner.image,
                            fit: BoxFit.fill,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
              SizedBox(height: height * 0.02),
              // 🔥 Featured Products Title
              // ✅ PRODUCTS SECTION — 3-column grid
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────
                  SectionHeader(
                    title: 'Top Picks',
                    onViewAll: () => Get.to(() => AllProductsPage()),
                  ),

                  SizedBox(height: height * 0.018),

                  // ── 3-column grid ─────────────────────────────
                  Obx(() {
                    if (productController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final products = productController.productList;
                    final displayCount = products.length > 6
                        ? 6
                        : products.length;

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: displayCount,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: width * 0.025,
                          mainAxisSpacing: height * 0.015,
                          childAspectRatio: gridChildAspectRatio,
                        ),
                        itemBuilder: (context, index) => PromoProductCard(
                          product: products[index],
                          wishlistController: wishlistController,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: height * 0.02),

              // ══════════════════════════════════════════════════
              // NEW: Dynamic curated category banner sections
              Obx(() {
                final categories = categoryController.categoryList;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < categories.length; i++)
                      _buildCategorySection(
                        context,
                        width,
                        height,
                        categoryId: categories[i].id.toString(),
                        title:
                            _sectionTitleTemplates[i %
                                    _sectionTitleTemplates.length]
                                .replaceAll('{category}', categories[i].name),
                        subtitle:
                            _sectionSubtitleTemplates[i %
                                    _sectionSubtitleTemplates.length]
                                .replaceAll('{category}', categories[i].name),
                      ),
                  ],
                );
              }),

              // SizedBox(height: height * 0.05),
              // AppFooterBranding(),
            ],
          ),
        ),
      ),
    );
  }

  void onSearchChanged(String value) async {
    if (value.isEmpty) {
      searchResults.clear();
      showSearchBox.value = false;
      return;
    }

    showSearchBox.value = true;

    await searchControllerX.filterBySearch(value);

    searchResults.value = List.from(searchControllerX.productList);
  }

  // ── Curated category banner section builder ─────────────────────
  Widget _buildCategorySection(
    BuildContext context,
    double width,
    double height, {
    required String categoryId,
    required String title,
    required String subtitle,
  }) {
    return Obx(() {
      final products = productController.productList
          .where((p) => p.categoryId.toString() == categoryId)
          .toList();

      if (products.isEmpty) {
        // No products in this category yet — hide the section instead
        // of showing an empty banner.
        return const SizedBox.shrink();
      }

      final display = products.length > 6 ? products.sublist(0, 6) : products;

      return Padding(
        padding: EdgeInsets.only(bottom: height * 0.025),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────
            SectionHeader(
              title: title,
              subtitle: subtitle,
              onViewAll: () => Get.to(() => AllProductsPage()),
            ),

            SizedBox(height: height * 0.012),

            // ── 3-column grid ─────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.04),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: display.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: width * 0.025,
                  mainAxisSpacing: height * 0.015,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) => PromoProductCard(
                  product: display[index],
                  wishlistController: wishlistController,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
