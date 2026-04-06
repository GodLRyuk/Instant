import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class ProductDetailsPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    int stock = widget.product.stock ?? 0;
    RxInt quantity = 1.obs;
    List<String> sizes = ["S", "M", "L", "XL"];

    return Scaffold(
      // extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: "Instant", isTransparent: false),
      backgroundColor: Colors.grey[100],

      /// 🔥 MODERN BOTTOM BAR
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: width * 0.04,
            vertical: height * 0.015,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Row(
            children: [
              /// ADD TO CART
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 50, // ✅ FIXED HEIGHT
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        "Add to Cart",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12),

              /// BUY NOW
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 50, // ✅ FIXED HEIGHT
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
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 IMAGE WITH OVERLAY
            Stack(
              children: [
                Container(
                  height: height * 0.4,
                  width: double.infinity,
                  color: Colors.white,
                  child: Image.network(
                    widget.product.image,
                    fit: BoxFit.contain,
                  ),
                ),

                /// BACK BUTTON
                Positioned(
                  top: 40,
                  left: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () => Get.back(),
                    ),
                  ),
                ),

                /// WISHLIST
                Positioned(
                  top: 40,
                  right: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.favorite_border),
                  ),
                ),
              ],
            ),

            SizedBox(height: height * 0.015),

            /// 🔥 PRODUCT INFO CARD
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
                  /// NAME
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: width * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  /// ⭐ RATING
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.orange, size: 18),
                      SizedBox(width: 4),
                      Text("4.5 (120 reviews)"),
                    ],
                  ),

                  SizedBox(height: 10),

                  /// PRICE
                  Row(
                    children: [
                      Text(
                        "₹${widget.product.discounted_price}",
                        style: TextStyle(
                          fontSize: width * 0.05,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "₹${widget.product.price}",
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 10),

                      /// DISCOUNT BADGE
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${widget.product.discount_percent.toString()} %",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.015),

            /// 🔥 SIZE CARD
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
                    "${widget.product.unit_size != null ? widget.product.unit_size.toInt().toString() : ''} ${widget.product.unit_name ?? ''}",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.015),

            /// 🔥 QUANTITY CARD
            stock == 0
                ? Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Center(
                      child: Text(
                        "Out of Stock",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
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
                          () => stock == 0
                              ? const Text(
                                  "Out of Stock",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (quantity.value > 1)
                                          quantity.value--;
                                      },
                                      icon: Icon(Icons.remove_circle_outline),
                                    ),

                                    Text(quantity.value.toString()),

                                    IconButton(
                                      onPressed: () {
                                        if (quantity.value < 5 &&
                                            quantity.value < stock) {
                                          quantity.value++;
                                        }
                                      },
                                      icon: Icon(Icons.add_circle_outline),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),

            SizedBox(height: height * 0.015),

            /// 🔥 DESCRIPTION CARD
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
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.product.description ?? "No description available",
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.1),
          ],
        ),
      ),
    );
  }
}
