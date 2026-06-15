import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/controllers/coupon_controller.dart';
import 'package:instant_delivery/pages/cart/payment_page.dart';
import 'package:instant_delivery/services/location_service.dart'
    as LocationService;
import 'package:instant_delivery/utils/delivery_charge.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class CheckoutPage extends StatefulWidget {
  /// Raw subtotal — before any discount.
  final double totalAmount;
  final List items;

  /// Pre-applied from CartPage. Empty string = not yet applied.
  final String appliedCouponCode;

  /// Pre-calculated discount from CartPage. 0.0 = none.
  final double discountAmount;

  const CheckoutPage({
    super.key,
    required this.totalAmount,
    required this.items,
    this.appliedCouponCode = '',
    this.discountAmount = 0.0,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final AddressController addressController = Get.put(AddressController());

  bool showAllItems = false;

  // ── Coupon state (inline apply — only used when NOT pre-applied) ──
  final TextEditingController _couponCtrl = TextEditingController();
  bool _isApplyingCoupon = false;
  String _couponError = '';
  String _localCouponCode = '';
  double _localDiscount = 0.0;
  final CouponController couponController = Get.put(CouponController());
  int get _totalQty => widget.items.fold<int>(
    0,
    (sum, item) => sum + (item['quantity'] as num).toInt(),
  );
  // ── Helpers ───────────────────────────────────────────────────────

  /// True when coupon was passed in from CartPage (read-only display).
  bool get _couponPreApplied => widget.appliedCouponCode.isNotEmpty;

  /// Whichever coupon is active (from cart OR applied inline here).
  String get _activeCouponCode {
    if (widget.appliedCouponCode.isNotEmpty) return widget.appliedCouponCode;
    if (couponController.appliedCode.value.isNotEmpty) {
      return couponController.appliedCode.value;
    }
    return _localCouponCode;
  }

  double get _activeDiscount =>
      _couponPreApplied ? widget.discountAmount : _localDiscount;

  /// Delivery is calculated on the discounted subtotal.
  double get deliveryCharge =>
      DeliveryCharge.calculate(widget.totalAmount - _activeDiscount);

  double get finalAmount =>
      (widget.totalAmount - _activeDiscount) +
      deliveryCharge -
      couponController.discountAmount.value;
  double get subtotal => widget.totalAmount + deliveryCharge;

  @override
  void initState() {
    super.initState();
    addressController.fetchAddresses();
  }

  @override
  void dispose() {
    _couponCtrl.dispose();
    super.dispose();
  }

  void _removeCoupon() {
    setState(() {
      _localCouponCode = '';
      _localDiscount = 0.0;
      _couponError = '';
      _couponCtrl.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(
        title: "Checkout",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    /// 🔴 ADDRESS SECTION
                    Container(
                      margin: EdgeInsets.all(width * 0.04),
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Delivery Address",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Obx(() {
                            if (addressController.isLoading.value) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (addressController.addressList.isEmpty) {
                              return const Text(
                                "No Address Found",
                                style: TextStyle(color: Colors.white70),
                              );
                            }

                            return Column(
                              children: addressController.addressList.map((
                                address,
                              ) {
                                final isSelected =
                                    addressController
                                        .selectedAddress
                                        .value
                                        ?.id ==
                                    address.id;

                                return GestureDetector(
                                  onTap: () =>
                                      addressController.selectAddress(address),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.green.shade50
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "${address.fullAddress}\n${address.city}, ${address.state} - ${address.pincode}",
                                            style: const TextStyle(height: 1.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          }),

                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const SizedBox(width: 10),
                              Expanded(
                                child: _addressButton(
                                  "Add Address",
                                  Icons.add_location,
                                  () => _showAddAddressSheet(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    /// 🧾 ORDER SUMMARY
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Order Summary",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          /// Items list with show-more
                          Column(
                            children: [
                              ...List.generate(
                                showAllItems
                                    ? widget.items.length
                                    : widget.items.take(3).length,
                                (index) {
                                  final item = showAllItems
                                      ? widget.items[index]
                                      : widget.items.take(3).toList()[index];

                                  final isLast =
                                      index ==
                                      (showAllItems
                                              ? widget.items.length
                                              : widget.items.take(3).length) -
                                          1;

                                  return Column(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                item["image"],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item["name"],
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Qty: ${item["quantity"]}",
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              "₹${item["price"] * item["quantity"]}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isLast)
                                        Divider(
                                          thickness: 0.8,
                                          color: Colors.grey.shade300,
                                          height: 16,
                                        ),
                                    ],
                                  );
                                },
                              ),

                              if (widget.items.length > 3)
                                GestureDetector(
                                  onTap: () => setState(
                                    () => showAllItems = !showAllItems,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          showAllItems
                                              ? "Show Less"
                                              : "Show More",
                                        ),
                                        Icon(
                                          showAllItems
                                              ? Icons.keyboard_arrow_up
                                              : Icons.keyboard_arrow_down,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const Divider(),

                          /// 🎟 COUPON — inline apply (product-details flow)
                          if (!_couponPreApplied) ...[
                            _buildInlineCouponSection(),
                            const SizedBox(height: 10),
                          ],

                          /// Delivery charge row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Delivery Charge"),
                              Text(
                                deliveryCharge == 0
                                    ? "Free"
                                    : "₹${deliveryCharge.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),

                          if (deliveryCharge == 0)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                "🎉 You got FREE delivery!",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Sub Total"),
                              Text(
                                "₹${subtotal.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Discounted Price"),
                              Text(
                                "₹${couponController.discountAmount.value.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "₹${finalAmount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),

            /// 🟢 CONFIRM ORDER BUTTON
            Container(
              padding: EdgeInsets.all(width * 0.02),
              width: width * 0.9,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (addressController.selectedAddress.value == null) {
                        Get.snackbar("Error", "Please select an address");
                        return;
                      }
                      try {
                        final locationData =
                            await LocationService.getCurrentAddress();
                        final String? lat = locationData["lat"];
                        final String? lng = locationData["lng"];

                        Get.to(
                          () => PaymentPage(
                            totalAmount: finalAmount,
                            items: widget.items,
                            address: addressController.selectedAddress.value,
                            couponCode: _activeCouponCode.isNotEmpty
                                ? _activeCouponCode
                                : null,
                            currentLat: lat, // ✅ NEW
                            currentLng: lng, // ✅ NEW
                          ),
                        );
                      } catch (e) {
                        Get.snackbar(
                          "Location Error",
                          "Could not get your location. Please enable GPS.",
                        );
                      }
                    },
                    child: const Text(
                      "Confirm Order",
                      style: TextStyle(color: Colors.white),
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

  // ── Inline coupon widget (product-details flow only) ─────────────
  Widget _buildInlineCouponSection() {
    return Obx(() {
      final isApplied = couponController.appliedCode.value.isNotEmpty;
      final isLoading = couponController.isLoading.value;
      final error = couponController.couponMessage.value;

      /// Coupon successfully applied — show success chip + remove button
      if (isApplied) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '"${couponController.appliedCode.value}" applied',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "You saved ₹${couponController.discountAmount.value.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              /// ✕ Remove coupon
              GestureDetector(
                onTap: _removeCoupon,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.shade400,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      /// Not yet applied — show input + Apply button
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "Enter coupon code",
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(
                      Icons.confirmation_number_outlined,
                      color: Colors.grey,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red.shade300),
                    ),
                    errorText: error.isNotEmpty ? error : null,
                    errorMaxLines: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: isLoading ? null : _applyCoupon,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Apply",
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      couponController.couponMessage.value = 'Please enter a coupon code';
      return;
    }

    await couponController.applyCoupon(
      code: code,
      orderTotal: widget.totalAmount, // raw subtotal before discount
      totalQty: _totalQty, // sum of quantities from widget.items
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────

  Widget _addressButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ── Add Address Bottom Sheet ──────────────────────────────────────
  void _showAddAddressSheet(BuildContext context) {
    final fullAddressCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Add New Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _inputFieldAddress(
                "Full Address",
                fullAddressCtrl,
                onTap: () => _showLocationConfirm(fullAddressCtrl),
              ),
              _inputField("Name", nameCtrl),
              _inputField("Phone", phoneCtrl),
              _inputField("City", cityCtrl),
              _inputField("State", stateCtrl),
              _inputField("Pincode", pincodeCtrl),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await addressController.addNewAddress(
                      fullAddress: fullAddressCtrl.text,
                      city: cityCtrl.text,
                      state: stateCtrl.text,
                      pincode: pincodeCtrl.text,
                    );
                    Get.back();
                    await addressController.fetchAddresses();
                  },
                  child: const Text(
                    "Save Address",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _inputField(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _inputFieldAddress(
    String label,
    TextEditingController controller, {
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showLocationConfirm(TextEditingController controller) {
    Get.defaultDialog(
      title: "Use Current Location?",
      middleText: "We will fetch your exact location",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        try {
          final data = await LocationService.getCurrentAddress();
          Get.back();
          controller.text = data["fullAddress"]!;
        } catch (e) {
          Get.back();
          Get.snackbar(
            "Error",
            "Failed to get location",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        Get.back();
      },
    );
  }
}
