import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/bundle_controller.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/bundle_strip.dart';
import 'package:instant_delivery/widgets/flash_sale_strip.dart';
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

  @override
  void initState() {
    super.initState();

    _midBannerController = PageController();

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
    _refreshData();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final bundleController = Get.find<BundleController>();

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
                    height: height * 0.06,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: width * 0.03),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
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

              // 🔥 Categories Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                child: Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: height * 0.005),
              // ✅ GETX CATEGORY LIST
              SizedBox(
                height: height * 0.13,
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
                          margin: EdgeInsets.only(left: width * 0.04),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: width * 0.08,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  getIcon(
                                    category.name,
                                  ), // or icon field if you add
                                  color: Colors.green,
                                  size: width * 0.07,
                                ),
                              ),
                              SizedBox(height: height * 0.008),
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

              SizedBox(height: height * 0.002),
              // 🔥 Banner
              Obx(() {
                if (topBannerController.isLoading.value) {
                  return SizedBox(
                    height: height * 0.2,
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  // Show the first banner from the list
                  final banner = topBannerController.topbannerList[0];

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                    height: height * 0.2,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(width * 0.04),
                      image: DecorationImage(
                        image: NetworkImage(banner.image), // <-- API image here
                        fit: BoxFit.fill,
                      ),
                    ),
                  );
                }
              }),
              SizedBox(height: height * 0.015),

              FlashSaleStrip(controller: flashSaleController),

              // 🔥 Products Title
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'New Arrival',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(() => AllProductsPage());
                      },
                      child: Text(
                        "View All",
                        style: TextStyle(
                          fontSize: width * 0.040,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.015),

              // ✅ PRODUCT GRID
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Obx(() {
                  if (productController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final newArrival = newArrivalController.newArrivalList;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // itemCount: newArrivalController.productList.length,
                    itemCount: newArrival.length > 4 ? 4 : newArrival.length,

                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: width * 0.03,
                      mainAxisSpacing: height * 0.02,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      final product = newArrival[index];

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(width * 0.04),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 5),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔥 Product Image
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(width * 0.04),
                                  ),
                                  child: Image.network(
                                    product.image,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.02,
                                  vertical: height * 0.008,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔥 Product Name
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    // 🔥 Price
                                    Text(
                                      "₹${product.price}",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: width * 0.035,
                                      ),
                                    ),
                                    SizedBox(height: height * 0.005),

                                    // 🔥 Add to Cart Button
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => ProductDetailsPage(
                                            product: product,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: height * 0.008,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            width * 0.02,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "View",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: width * 0.035,
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
              SizedBox(height: height * 0.015),

              const BundleStrip(),

              SizedBox(height: height * 0.015),
              if (recommendedController.recommendedList.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended for you',
                        style: TextStyle(
                          fontSize: width * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Get.to(() => AllProductsPage());
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            fontSize: width * 0.040,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: height * 0.015),

                // 🔥 Horizontal Product List (Different Design)
                SizedBox(
                  height: height * 0.23,
                  width: double.infinity,
                  child: Obx(() {
                    if (recommendedController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommendedController.recommendedList.length,
                      itemBuilder: (context, index) {
                        final product =
                            recommendedController.recommendedList[index];

                        return Container(
                          width: width * 0.4,
                          margin: EdgeInsets.only(
                            left: width * 0.04,
                            bottom: height * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(width * 0.04),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔥 Image
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(width * 0.04),
                                    ),
                                    child: Image.network(
                                      product.image,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 🔥 Name
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: width * 0.035,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(height: height * 0.005),

                                    // 🔥 Price
                                    Text(
                                      "₹${product.price}",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    SizedBox(height: height * 0.008),

                                    // 🔥 Add Button (Small pill style)
                                    GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => ProductDetailsPage(
                                            product: product,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: height * 0.006,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            width * 0.02,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            "View",
                                            style: TextStyle(
                                              color: Colors.white,
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
                        );
                      },
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
              // ✅ PRODUCTS SECTION — Horizontal Strip Design
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Top\n',
                                style: TextStyle(
                                  fontSize: width * 0.08,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.shade700,
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              ),
                              TextSpan(
                                text: 'Picks',
                                style: TextStyle(
                                  fontSize: width * 0.08,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[900],
                                  height: 1.0,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.to(() => AllProductsPage()),
                          child: Row(
                            children: [
                              Text(
                                'See all',
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: height * 0.018),

                  // ── Horizontal card list ─────────────────────
                  Obx(() {
                    if (productController.isLoading.value) {
                      return SizedBox(
                        height: height * 0.26,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }

                    final products = productController.productList;
                    final displayCount = products.length > 6
                        ? 6
                        : products.length;

                    return SizedBox(
                      height: height * 0.23,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(left: width * 0.05),
                        itemCount: displayCount,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          return GestureDetector(
                            onTap: () => Get.to(
                              () => ProductDetailsPage(product: product),
                            ),
                            child: Container(
                              width: width * 0.36,
                              margin: EdgeInsets.only(
                                right: width * 0.03,
                                bottom: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image with index badge
                                  Stack(
                                    children: [
                                      Container(
                                        height: height * 0.14,
                                        decoration: BoxDecoration(
                                          color: index.isEven
                                              ? Colors.white
                                              : Colors.white,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                          child: Image.network(
                                            product.image,
                                            width: double.infinity,
                                            fit: BoxFit.contain,
                                            errorBuilder: (_, __, ___) => Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[300],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Index badge
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[900],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '#${index + 1}',
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

                                  // Info
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        10,
                                        8,
                                        10,
                                        10,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: width * 0.032,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.grey[850],
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '₹${product.price.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: width * 0.038,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: height * 0.05),
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
}
