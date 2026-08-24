import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import 'package:instant_delivery/controllers/coupon_controller.dart';
import 'package:instant_delivery/controllers/pass_controller.dart';
import 'package:instant_delivery/pages/cart/checkout_page.dart';
import 'package:instant_delivery/pages/membership/pass_purchase_screen.dart';
import 'package:instant_delivery/services/api_service.dart';
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
  final PassController passController = Get.put(PassController());

  // ── Scheduling state ──────────────────────────────────────────
  String _deliveryType = 'ASAP'; // 'ASAP' or 'SCHEDULED'
  List<dynamic> _slotDays = [];
  bool _slotsLoading = true;
  int _selectedDayIndex = 0;
  String? _selectedSlotStart;
  String? _selectedSlotEnd;
  final AddressController addressController = Get.put(AddressController());

  final RxDouble estimatedDeliveryFee = 0.0.obs;
  final RxBool isFeeLoading = false.obs;
  final RxString feeError = ''.obs;
  @override
  void initState() {
    super.initState();
    cartController.fetchCart();
    _fetchSlots();
    addressController.fetchAddresses().then((_) {
      if (addressController.selectedAddress.value != null) {
        _fetchDeliveryFee();
      }
    });
    ever(addressController.selectedAddress, (_) {
      _fetchDeliveryFee();
    });
    // Re-fetch fee if cart contents change quantity/items, since fee can depend on order size
    ever(cartController.cartItems, (_) {
      if (addressController.selectedAddress.value != null) {
        _fetchDeliveryFee();
      }
    });
  }

  @override
  void dispose() {
    _couponTextCtrl.dispose();
    super.dispose();
  }

  // ── Slot helpers ──────────────────────────────────────────────
  Future<void> _fetchSlots() async {
    try {
      final slots = await ApiService().getDeliverySlots();
      setState(() {
        _slotDays = slots;
        _slotsLoading = false;
      });
    } catch (_) {
      setState(() => _slotsLoading = false);
    }
  }

  String _formatSlotTime(String time24) {
    final parts = time24.split(':');
    int hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  List<dynamic> get _currentSlots =>
      _slotDays.isEmpty ? [] : (_slotDays[_selectedDayIndex]['slots'] ?? []);

  String? _toBackendTime(String? t) {
    if (t == null) return null;
    if (!t.contains('AM') && !t.contains('PM')) {
      return t.length == 5 ? '$t:00' : t;
    }
    final parts = t.split(' ');
    final tp = parts[0].split(':');
    int h = int.parse(tp[0]);
    if (parts[1] == 'PM' && h != 12) h += 12;
    if (parts[1] == 'AM' && h == 12) h = 0;
    return '${h.toString().padLeft(2, '0')}:${tp[1]}:00';
  }

  Future<void> _fetchDeliveryFee() async {
    final address = addressController.selectedAddress.value;
    if (address == null) return;

    isFeeLoading.value = true;
    feeError.value = '';

    try {
      final apiItems = cartController.cartItems
          .map(
            (item) => {"product": item.product_id, "quantity": item.quantity},
          )
          .toList();

      final res = await ApiService().validateOrder(
        items: apiItems,
        addressId: address.id,
        currentLat: null,
        currentLng: null,
      );

      if (res["statusCode"] == 200) {
        final data = res["data"];
        estimatedDeliveryFee.value = (data["delivery_fee"] as num).toDouble();
      } else {
        final data = res["data"];
        String msg = "Could not calculate delivery fee for this address.";
        if (data is Map) {
          final val = data.values.first;
          msg = val is List ? val.first.toString() : val.toString();
        }
        feeError.value = msg;
        estimatedDeliveryFee.value = 0.0;
      }
    } catch (e) {
      feeError.value = "Failed to check delivery availability.";
      estimatedDeliveryFee.value = 0.0;
    } finally {
      isFeeLoading.value = false;
    }
  }

  // ── Build ─────────────────────────────────────────────────────
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
        // final delivery = passController.hasPass.value && cartTotal >= 149
        //     ? 0.0
        //     : DeliveryCharge.calculate(cartTotal);

        final minOrder = 149;
        final delivery = passController.hasPass.value && cartTotal >= minOrder
            ? 0.0
            : estimatedDeliveryFee.value;
        final discount = couponController.discountAmount.value;
        final subtotal = cartTotal + delivery;
        final finalAmount = subtotal - discount;

        return Column(
          children: [
            // ── ITEMS ──────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(25),
                itemCount: cartController.cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartController.cartItems[index];

                  return Dismissible(
                    key: Key(item.product + index.toString()),
                    direction: DismissDirection.endToStart,
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
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          // Image
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
                          // Details
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
                                // Quantity
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

            // ── COUPON ─────────────────────────────────────────
            _buildCouponSection(),
            SizedBox(height: 10),
            // ── PASS BANNER ────────────────────────────────────
            _buildPassBanner(),

            // ── DELIVERY SCHEDULER ─────────────────────────────
            _buildDeliveryScheduler(),

            // ── SUMMARY ────────────────────────────────────────
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
                  _row("Discount", -discount, valueColor: Colors.green),
                  const Divider(),
                  _row("Total", finalAmount, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── CHECKOUT BUTTON ────────────────────────────────
            _buildCheckoutButton(finalAmount),
          ],
        );
      }),
    );
  }

  // ── DELIVERY SCHEDULER ───────────────────────────────────────
  Widget _buildDeliveryScheduler() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          // Toggle row
          Row(
            children: [
              _scheduleToggleBtn('ASAP', Icons.bolt, 'Instant', '20–30 min'),
              const SizedBox(width: 8),
              _scheduleToggleBtn(
                'SCHEDULED',
                Icons.calendar_month,
                'Schedule',
                'Pick date & time',
              ),
            ],
          ),

          // Expanded picker (only when SCHEDULED)
          if (_deliveryType == 'SCHEDULED') ...[
            const SizedBox(height: 14),
            if (_slotsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              // ── DATE ROW ──
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Color(0xFF3CB549),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Select date',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 62,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _slotDays.length,
                  itemBuilder: (_, i) {
                    final day = _slotDays[i];
                    final isSelected = _selectedDayIndex == i;
                    final label = day['is_today'] == true
                        ? 'Today'
                        : day['day'];
                    final dateNum = (day['date'] as String).split('-').last;

                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedDayIndex = i;
                        _selectedSlotStart = null;
                        _selectedSlotEnd = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        width: 52,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE8F5E9)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFA5D6A7)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              label.toString().substring(0, 3),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateNum,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // ── TIME SLOTS ──
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Color(0xFF3CB549),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Select time slot',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_currentSlots.where((s) => s['available'] == true).length} available',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.2,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: _currentSlots.length,
                itemBuilder: (_, i) {
                  final slot = _currentSlots[i];
                  final isAvailable = slot['available'] == true;
                  final slotStart = slot['slot_start'] as String;
                  final slotEnd = slot['slot_end'] as String;
                  final isSelected = _selectedSlotStart == slotStart;

                  return GestureDetector(
                    onTap: isAvailable
                        ? () => setState(() {
                            _selectedSlotStart = slotStart;
                            _selectedSlotEnd = slotEnd;
                          })
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE8F5E9)
                            : isAvailable
                            ? Colors.white
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFA5D6A7)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '${_formatSlotTime(slotStart)} – ${_formatSlotTime(slotEnd)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFF2E7D32)
                              : isAvailable
                              ? Colors.black87
                              : Colors.grey.shade400,
                          decoration: isAvailable
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _scheduleToggleBtn(
    String type,
    IconData icon,
    String label,
    String sub,
  ) {
    final isActive = _deliveryType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _deliveryType = type;
          _selectedSlotStart = null;
          _selectedSlotEnd = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8F5E9) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? const Color(0xFFA5D6A7) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                size: 20,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive
                      ? const Color(0xFF388E3C)
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PASS BANNER ───────────────────────────────────────────────
  Widget _buildPassBanner() {
    return Obx(() {
      if (passController.isLoading.value) return const SizedBox.shrink();

      if (passController.hasPass.value) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() {
                  final subtotal = cartController.cart.value?.cartTotal ?? 0;
                  if (subtotal >= 149) {
                    return const Text(
                      "✅ Free delivery applied with your Pass!",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    );
                  }
                  return Text(
                    "Add ₹${(149 - subtotal).toStringAsFixed(0)} more for free delivery",
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      }

      return GestureDetector(
        onTap: () => Get.to(() => const PassPurchasePage()),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Get FREE delivery on every order!\nDelivery Pass from ₹99/month →",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ],
          ),
        ),
      );
    });
  }

  // ── CHECKOUT BUTTON ───────────────────────────────────────────
  Widget _buildCheckoutButton(double finalAmount) {
    return Container(
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
          // Validate slot selection when scheduled
          if (_deliveryType == 'SCHEDULED' &&
              (_selectedSlotStart == null || _selectedSlotEnd == null)) {
            Get.snackbar(
              'Select a time slot',
              'Please pick a date and time slot before checking out',
              snackPosition: SnackPosition.BOTTOM,
            );
            return;
          }

          final items = cartController.cartItems.map((item) {
            return {
              "product": item.product_id,
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
              deliveryType: _deliveryType,
              scheduledDate: _deliveryType == 'SCHEDULED'
                  ? _slotDays[_selectedDayIndex]['date']
                  : null,
              scheduledSlotStart: _toBackendTime(_selectedSlotStart),
              scheduledSlotEnd: _toBackendTime(_selectedSlotEnd),
            ),
          );
        },
        child: Center(
          child: Text(
            _deliveryType == 'ASAP'
                ? 'Check Out — Instant'
                : _selectedSlotStart != null
                ? 'Check Out — ${_formatSlotTime(_selectedSlotStart!)}'
                : 'Check Out',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  // ── COUPON SECTION ────────────────────────────────────────────
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
                  Obx(() {
                    if (couponController.couponMessage.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
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

  // ── HELPERS ───────────────────────────────────────────────────
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
