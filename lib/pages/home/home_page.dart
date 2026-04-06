import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/pages/product/all_products.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

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
  late PageController _midBannerController;
  final ProductController bannerController = Get.put(ProductController());
  final ProductController topBannerController = Get.put(ProductController());
  int _currentPage = 0;
  Timer? _timer;

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
    await Future.wait<void>([
      categoryController.fetchCategories(),
      productController.fetchProducts(),
      newArrivalController.fetchNewArrivals(),
      recommendedController.fetchRecommended(),
      bannerController.fetchBanners(),
      topBannerController.fetchTopBanners(),
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
              Container(
                margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                height: height * 0.06,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xfff5f5f5)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(width * 0.015),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.search, color: Colors.orange),
                    ),
                    SizedBox(width: width * 0.03),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search products...",
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: width * 0.035,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Icon(Icons.mic, color: Colors.grey.shade400),
                  ],
                ),
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
                          fontSize: width * 0.035,
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

              SizedBox(height: height * 0.00),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Text(
                  'Recommended for you',
                  style: TextStyle(
                    fontSize: width * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: height * 0.015),

              // 🔥 Horizontal Product List (Different Design)
              SizedBox(
                height: height * 0.23,
                width: double.infinity,
                child: Obx(() {
                  if (productController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final recomended = recommendedController.recommendedList;

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
                                          style: TextStyle(color: Colors.white),
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
                  height: height * 0.18,
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Products',
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.01),

              // ✅ PRODUCT GRID
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Obx(() {
                  if (productController.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = productController.productList;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length > 3 ? 3 : products.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: width * 0.03,
                      mainAxisSpacing: height * 0.001,
                      childAspectRatio: 0.70, // 🔥 reduce this
                    ),
                    itemBuilder: (context, index) {
                      final product = productController.productList[index];

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
                                    product.image, // 🔥 API field
                                    width: double.infinity,
                                    fit: BoxFit.fitWidth,
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

              SizedBox(height: height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
