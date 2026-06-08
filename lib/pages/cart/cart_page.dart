import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import 'package:instant_delivery/controllers/coupon_controller.dart';
import 'package:instant_delivery/pages/cart/checkout_page.dart';
import 'package:instant_delivery/utils/delivery_charge.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cartController = Get.put(CartController());
  final CouponController couponController = Get.put(CouponController());
  final TextEditingController _couponTextCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    cartController.fetchCart();
  }

  @override
  void dispose() {
    _couponTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: const CustomAppBar(
        title: "My Cart",
        isTransparent: false,
        showBackButton: false,
      ),

      body: Obx(() {
        if (cartController.isUpdating.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final cartTotal = cartController.cart.value?.cartTotal ?? 0;
        final delivery = DeliveryCharge.calculate(cartTotal);
        final discount = couponController.discountAmount.value;
        final subtotal = cartTotal + delivery;
        final finalAmount = subtotal - discount;

        return Column(
          children: [
            /// 🛒 ITEMS
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
                      return success;
                    },

                    /// 🟢 CARD (this was missing!)
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

            /// 🎟 COUPON
            _buildCouponSection(),

            /// 💳 SUMMARY (FULLY REACTIVE FIX)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _row("Cart Total", cartTotal),
                  _row("Delivery fee", delivery),
                  const Divider(),
                  _row("Sub Total", subtotal),
                  const Divider(),
                  // if (discount > 0)
                  _row("Discount ", -discount, valueColor: Colors.green),
                  const Divider(),
                  _row("Total", finalAmount, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 🟢 CHECKOUT
            Container(
              margin: const EdgeInsets.all(12),
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
                  final items = cartController.cartItems.map((item) {
                    return {
                      "name": item.product,
                      "price": item.price,
                      "quantity": item.quantity,
                      "image": item.image,
                    };
                  }).toList();

                  Get.to(
                    () => CheckoutPage(
                      totalAmount: finalAmount,
                      items: items,
                      appliedCouponCode: couponController.appliedCode.value,
                      discountAmount: couponController.discountAmount.value,
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    "Check Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  // ── COUPON SECTION ─────────────────────────────
  Widget _buildCouponSection() {
    return Obx(() {
      if (couponController.isApplied.value) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  couponController.appliedCode.value,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: () {
                  couponController.removeCoupon();
                  _couponTextCtrl.clear();
                },
                child: const Icon(Icons.close, color: Colors.red),
              ),
            ],
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: couponController.couponMessage.value.isNotEmpty
                ? Colors.red.shade300
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined),
            const SizedBox(width: 8),

            /// 📝 INPUT + ERROR stacked
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _couponTextCtrl,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter coupon code",
                    ),
                  ),

                  /// 🔴 ERROR MESSAGE (between input and Apply button)
                  Obx(() {
                    if (couponController.couponMessage.value.isEmpty)
                      return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              couponController.couponMessage.value,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            TextButton(
              onPressed: () {
                couponController.applyCoupon(
                  code: _couponTextCtrl.text,
                  orderTotal: cartController.cart.value?.cartTotal ?? 0,
                  totalQty: cartController.cartItems.fold<int>(
                    0,
                    (int sum, item) => sum + (item.quantity as num).toInt(),
                  ),
                );
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      );
    });
  }

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

  Widget _row(
    String title,
    double value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
