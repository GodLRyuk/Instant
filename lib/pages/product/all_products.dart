import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/models/product_model.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

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

  /// ✅ STORE SEARCH RESULTS LOCALLY
  List<ProductModel> searchResults = [];

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

    /// 🔥 CRITICAL FIX: delay any Rx update safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isSearch && Get.arguments != null) {
        final all = Get.arguments['results'];

        productController.productList.assignAll(all);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBar(
        title: "All Products",
        isTransparent: false,
        showBackButton: true,
      ),

      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        /// ✅ EMPTY STATE
        // if (productController.productList.isEmpty) {
        //   return const Center(child: Text("No products found"));
        // }

        return CustomScrollView(
          slivers: [
            /// 🔥 HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: width * 0.0),
                          padding: EdgeInsets.symmetric(
                            horizontal: width * 0.04,
                          ),
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
                                      final controller =
                                          Get.find<ProductController>(
                                            tag: "search",
                                          );

                                      await controller.filterBySearch(value);

                                      Get.to(
                                        () => AllProductsPage(),
                                        arguments: {
                                          "isSearch": true,
                                          "results": controller.productList
                                              .toList(),
                                        },
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
                                          final value = searchController.text
                                              .trim();

                                          if (value.isNotEmpty) {
                                            final controller =
                                                Get.find<ProductController>(
                                                  tag: "search",
                                                );

                                            await controller.filterBySearch(
                                              value,
                                            );

                                            Get.to(
                                              () => AllProductsPage(),
                                              arguments: {
                                                "isSearch": true,
                                                "results": controller
                                                    .productList
                                                    .toList(),
                                              },
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
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ),
            ),

            /// 🔘 CATEGORY CHIPS
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Obx(() {
                  final categories = [
                    {"id": "all", "name": "All"},
                    ...categoryController.categoryList.map(
                      (c) => {"id": c.id.toString(), "name": c.name},
                    ),
                  ];

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((category) {
                        final isSelected =
                            selectedCategoryId.value == category['id'];

                        return buildChip(
                          id: category['id']!,
                          text: category['name']!,
                          isSelected: isSelected,
                          onTap: () async {
                            selectedCategoryId.value = category['id']!;

                            if (isSearch) {
                              /// 🔍 FILTER SEARCH RESULTS
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                final all = Get.arguments?['results'] ?? [];

                                if (category['id'] == "all") {
                                  productController.productList.assignAll(all);
                                } else {
                                  productController.productList.assignAll(
                                    all
                                        .where(
                                          (p) =>
                                              p.category.toString() ==
                                              category['id'],
                                        )
                                        .toList(),
                                  );
                                }
                              });
                            } else {
                              /// 🌐 CALL API FOR CATEGORY
                              if (category['id'] == "all") {
                                await productController.fetchProducts();
                              } else {
                                await productController.fetchProductsByCategory(
                                  category['id']!,
                                );
                              }
                            }
                          },
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 15)),

            /// 🛒 PRODUCT GRID
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.02,
              ).copyWith(bottom: 120),
              sliver:
                  /// 🛒 PRODUCT LIST (AMAZON STYLE)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = productController.productList[index];

                      return GestureDetector(
                        onTap: () {
                          Get.to(() => ProductDetailsPage(product: product));
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              /// 🖼 LEFT IMAGE
                              Container(
                                width: width * 0.40,
                                height: height * 0.20,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.network(
                                  product.image,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              const SizedBox(width: 12),

                              /// 📄 RIGHT DETAILS
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// NAME
                                    Text(
                                      product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    /// UNIT
                                    Text(
                                      "${product.unit_size} ${product.unit_name}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    /// PRICE + BUTTON ROW
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Price: ₹ ${product.price.toStringAsFixed(0)}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF53D288),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Discounted Price: ${product.discounted_price}",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Available Qty: ${product.stock}",
                                      style: TextStyle(
                                        color: product.stock! <= 10
                                            ? Colors.red
                                            : Colors.grey.shade600,
                                        fontSize: 15,
                                        fontWeight: FontWeight(500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: productController.productList.length),
                  ),
            ),
          ],
        );
      }),
    );
  }

  /// 🔘 CHIP UI
  Widget buildChip({
    required String id,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF53D288), Color.fromARGB(255, 136, 198, 65)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
