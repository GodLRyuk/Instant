import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/category_controller.dart';
import 'package:instant_delivery/controllers/product_controller.dart';
import 'package:instant_delivery/pages/product/product_details_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class AllProductsPage extends StatefulWidget {
  const AllProductsPage({super.key});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  final ProductController productController = Get.find<ProductController>();
  final CategoryController categoryController = Get.put(CategoryController());

  var selectedCategoryId = "all".obs;

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
                    Text(
                      "Explore",
                      style: TextStyle(
                        fontSize: width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Collections",
                      style: TextStyle(
                        fontSize: width * 0.08,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ),
            ),

            /// 🔘 CATEGORY CHIPS (SCROLLABLE)
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

                            if (category['id'] == "all") {
                              await productController.fetchProducts();
                            } else {
                              await productController.fetchProductsByCategory(
                                category['id']!,
                              );
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

            /// 🛒 PRODUCT GRID (FIXED SLIVER GRID)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05)
                  .copyWith(bottom: 120),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product =
                        productController.productList[index];

                    return Transform.translate(
                      offset: Offset(0, index.isEven ? 50 : 5),
                      child: GestureDetector(
                        onTap: () {
                          Get.to(() =>
                              ProductDetailsPage(product: product));
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF53D288),
                                Color.fromARGB(255, 136, 198, 65),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🖼 IMAGE
                              Expanded(
                                flex: 7,
                                child: Container(
                                  margin: const EdgeInsets.all(10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: Image.network(
                                      product.image,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),

                              /// 📝 DETAILS
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              product.name,
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            "₹${product.price.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${product.unit_size} ${product.unit_name}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount:
                      productController.productList.length,
                ),

                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

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
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF53D288),
              Color.fromARGB(255, 136, 198, 65),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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