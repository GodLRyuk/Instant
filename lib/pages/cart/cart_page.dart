import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import 'package:instant_delivery/pages/cart/checkout_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cartController = Get.put(CartController());

  @override
  void initState() {
    super.initState();
    cartController.fetchCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const CustomAppBar(
        title: "My Cart",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        if (cartController.isUpdating.value) {
          return Container(
            color: const Color.fromARGB(255, 228, 228, 228).withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        return Column(
          children: [
            /// 🛒 LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(25),
                itemCount: cartController.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartController.cartItems[index];

                  return Dismissible(
                    key: Key(item.product + index.toString()),
                    direction: DismissDirection.endToStart,

                    /// 🔴 DELETE BACKGROUND
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.only(right: 20),
                      alignment: Alignment.centerRight,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),

                    confirmDismiss: (direction) async {
                      final success = await cartController.removeFromCart(
                        item.product_id,
                      );
                      return success; // ✅ IMPORTANT
                    },

                    /// 🟢 CARD
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          /// 🖼 IMAGE
                          Container(
                            height: 70,
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: item.image != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      item.image!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag),
                          ),

                          const SizedBox(width: 12),

                          /// 📦 DETAILS
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Price: ₹${item.price}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 6),

                                /// 🔢 QUANTITY
                                Row(
                                  children: [
                                    _qtyBtn(Icons.remove, () async {
                                      if (item.quantity > 1) {
                                        await cartController.updateQuantity(
                                          item.product_id,
                                          item.quantity - 1,
                                        );
                                      }
                                    }),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text("${item.quantity}"),
                                    ),

                                    _qtyBtn(Icons.add, () async {
                                      await cartController.updateQuantity(
                                        item.product_id,
                                        item.quantity + 1,
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            /// 💳 SUMMARY CARD
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _row("Total", cartController.cart.value?.cartTotal ?? 0),
                  _row("Delivery fee", 35),
                  const Divider(),
                  _row(
                    "Sub Total",
                    (cartController.cart.value?.cartTotal ?? 0) + 35,
                  ),
                ],
              ),
            ),

            /// 🟢 CHECKOUT BUTTON
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              width: double.infinity,
              height: 55,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.lightGreen],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: GestureDetector(
                onTap: () {
                  final cartItems = cartController.cartItems;

                  final totalAmount =
                      (cartController.cart.value?.cartTotal ?? 0) + 35;

                  /// 🔥 Convert cart items to checkout format
                  final items = cartItems.map((item) {
                    return {
                      "name": item.product,
                      "price": item.price,
                      "quantity": item.quantity,
                      "image": item.image,
                    };
                  }).toList();

                  Get.to(
                    () => CheckoutPage(totalAmount: totalAmount, items: items),
                  );
                },
                child: const Center(
                  child: Text(
                    "Check Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// 🔹 Quantity Button
  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }

  /// 🔹 Row Helper
  Widget _row(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700])),
          Text("₹$value", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
