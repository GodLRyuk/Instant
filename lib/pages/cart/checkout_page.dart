import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/controllers/coupon_controller.dart';
import 'package:instant_delivery/controllers/pass_controller.dart';
import 'package:instant_delivery/pages/cart/payment_page.dart';
import 'package:instant_delivery/pages/membership/pass_purchase_screen.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/location_service.dart'
    as LocationService;
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class CheckoutPage extends StatefulWidget {
  final double totalAmount;
  final List items;
  final String appliedCouponCode;
  final double discountAmount;
  final String deliveryType;
  final String? scheduledDate;
  final String? scheduledSlotStart;
  final String? scheduledSlotEnd;

  const CheckoutPage({
    super.key,
    required this.totalAmount,
    required this.items,
    this.appliedCouponCode = '',
    this.discountAmount = 0.0,
    this.deliveryType = 'ASAP',
    this.scheduledDate,
    this.scheduledSlotStart,
    this.scheduledSlotEnd,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final AddressController addressController = Get.put(AddressController());
  final CouponController couponController = Get.put(CouponController());
  final PassController passController = Get.put(PassController()); // ← add

  bool showAllItems = false;
  bool showHiddenCharges = false;
  List<Map<String, dynamic>> get _hiddenCharges => [
    {"label": "Paper Bag Charge", "amount": 10.0},
    // {"label": "Carry Bag Charge", "amount": 5.0},
  ];
  double get _hiddenChargesTotal => _hiddenCharges.fold<double>(
    0.0,
    (sum, c) => sum + (c["amount"] as double),
  );
  final RxBool isConfirmingOrder = false.obs;
  final RxDouble estimatedDeliveryFee = 0.0.obs;
  final RxBool isFeeLoading = false.obs;
  final RxString feeError = ''.obs;

  final TextEditingController _couponCtrl = TextEditingController();
  String _localCouponCode = '';
  double _localDiscount = 0.0;

  int get _totalQty => widget.items.fold<int>(
    0,
    (sum, item) => sum + (item['quantity'] as num).toInt(),
  );

  bool get _couponPreApplied => widget.appliedCouponCode.isNotEmpty;

  String get _activeCouponCode {
    if (widget.appliedCouponCode.isNotEmpty) return widget.appliedCouponCode;
    if (couponController.appliedCode.value.isNotEmpty) {
      return couponController.appliedCode.value;
    }
    return _localCouponCode;
  }

  double get _activeDiscount =>
      _couponPreApplied ? widget.discountAmount : _localDiscount;

  // ── Delivery fee — free if pass active and subtotal ≥ min ────────
  double get deliveryCharge {
    final subtotal = widget.totalAmount - _activeDiscount;
    final minOrder = passController.freeDeliveryMinOrder.value;

    if (passController.hasPass.value && subtotal >= minOrder) {
      return 0.0; // free with pass — unchanged
    }

    return estimatedDeliveryFee
        .value; // ✅ was: DeliveryCharge.calculate(subtotal)
  }

  double get finalAmount =>
      (widget.totalAmount - _activeDiscount) +
      deliveryCharge -
      couponController.discountAmount.value +
      _hiddenChargesTotal;

  double get subtotal =>
      widget.totalAmount + deliveryCharge + _hiddenChargesTotal;

  @override
  void initState() {
    super.initState();
    addressController.fetchAddresses().then((_) {
      if (addressController.selectedAddress.value != null) {
        _fetchDeliveryFee();
      }
    });
    ever(addressController.selectedAddress, (_) {
      _fetchDeliveryFee();
    });
  }

  Future<void> _fetchDeliveryFee() async {
    final address = addressController.selectedAddress.value;
    if (address == null) return;

    isFeeLoading.value = true;
    feeError.value = '';

    try {
      final apiItems = widget.items
          .map(
            (item) => {
              "product": item["product"],
              "quantity": item["quantity"],
            },
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
        String msg =
            data['non_field_errors']?.first?.toString() ??
            "Delivery not available for this address.";
        if (data is Map) {
          final val = data.values.first;
          msg = val is List ? val.first.toString() : val.toString();
        }
        feeError.value = msg;
        estimatedDeliveryFee.value = 0.0;
      }
    } catch (e) {
      feeError.value = "Delivery not available for this address.";
      estimatedDeliveryFee.value = 0.0;
    } finally {
      isFeeLoading.value = false;
    }
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
      _couponCtrl.clear();
    });
  }

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
                    // ── PASS BANNER ────────────────────────────
                    _buildPassBanner(width),

                    /// ADDRESS SECTION
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
                            color: Colors.black.withValues(alpha: 0.05),
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

                    /// ORDER SUMMARY
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: width * 0.04),
                      padding: EdgeInsets.all(width * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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

                          // Items list
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

                          // Coupon section
                          if (!_couponPreApplied) ...[
                            _buildInlineCouponSection(),
                            const SizedBox(height: 10),
                          ],

                          // Delivery charge row
                          Obx(() {
                            if (isFeeLoading.value) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Delivery Charge"),
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (feeError.value.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        feeError.value,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Delivery Charge"),
                                Text(
                                  deliveryCharge == 0
                                      ? "FREE"
                                      : "₹${deliveryCharge.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: deliveryCharge == 0
                                        ? Colors.green
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            );
                          }),

                          // Pass free delivery badge
                          if (passController.hasPass.value &&
                              deliveryCharge == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    color: Colors.green,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Free delivery with your Pass 🎉",
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Not enough for free delivery hint
                          if (passController.hasPass.value &&
                              deliveryCharge > 0) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Add ₹${(passController.freeDeliveryMinOrder.value - (widget.totalAmount - _activeDiscount)).toStringAsFixed(0)} more for free delivery",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const Divider(),
                          GestureDetector(
                            onTap: () => setState(
                              () => showHiddenCharges = !showHiddenCharges,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text("Hidden Charges"),
                                    Icon(
                                      showHiddenCharges
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                                Text(
                                  "₹${_hiddenChargesTotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 200),
                            crossFadeState: showHiddenCharges
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.only(top: 8, left: 8),
                              child: Column(
                                children: _hiddenCharges.map((charge) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          charge["label"],
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          "₹${(charge["amount"] as double).toStringAsFixed(2)}",
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            secondChild: const SizedBox.shrink(),
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

            /// CONFIRM ORDER BUTTON
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
                      disabledBackgroundColor: Colors.green.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isConfirmingOrder.value
                        ? null
                        : () async {
                            if (addressController.selectedAddress.value ==
                                null) {
                              Get.snackbar("Error", "Please select an address");
                              return;
                            }
                            if (feeError.value.isNotEmpty) {
                              // ✅ NEW
                              Get.snackbar(
                                "Delivery Unavailable",
                                feeError.value,
                              );
                              return;
                            }

                            isConfirmingOrder.value = true;
                            try {
                              final locationData =
                                  await LocationService.getCurrentAddress();
                              final String? lat = locationData["lat"];
                              final String? lng = locationData["lng"];
                              Get.to(
                                () => PaymentPage(
                                  totalAmount: finalAmount,
                                  items: widget.items,
                                  address:
                                      addressController.selectedAddress.value,
                                  couponCode: _activeCouponCode.isNotEmpty
                                      ? _activeCouponCode
                                      : null,
                                  currentLat: lat,
                                  currentLng: lng,
                                  // ✅ add these
                                  deliveryType: widget.deliveryType,
                                  scheduledDate: widget.scheduledDate,
                                  scheduledSlotStart: widget.scheduledSlotStart,
                                  scheduledSlotEnd: widget.scheduledSlotEnd,
                                ),
                              );
                            } catch (e) {
                              Get.snackbar(
                                "Location Error",
                                "Could not get your location. Please enable GPS.",
                              );
                            } finally {
                              // Always clear the loading state, whether we
                              // navigated away, hit an error, or the
                              // location call threw.
                              isConfirmingOrder.value = false;
                            }
                          },
                    child: isConfirmingOrder.value
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
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

  // ── PASS BANNER ──────────────────────────────────────────────────
  Widget _buildPassBanner(double width) {
    // Has active pass
    if (passController.hasPass.value) {
      final subtotal = widget.totalAmount - _activeDiscount;
      final minOrder = passController.freeDeliveryMinOrder.value;
      final qualifies = subtotal >= minOrder;

      return Container(
        margin: EdgeInsets.fromLTRB(
          width * 0.04,
          width * 0.04,
          width * 0.04,
          0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: qualifies ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: qualifies ? Colors.green.shade200 : Colors.orange.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              qualifies ? Icons.verified : Icons.delivery_dining,
              color: qualifies ? Colors.green : Colors.orange,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                qualifies
                    ? "✅ Free delivery applied with your Pass!"
                    : "Add ₹${(minOrder - subtotal).toStringAsFixed(0)} more for free delivery (Pass benefit)",
                style: TextStyle(
                  color: qualifies
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // No pass — show upsell banner
    return GestureDetector(
      onTap: () => Get.to(() => const PassPurchasePage()),
      child: Container(
        margin: EdgeInsets.fromLTRB(
          width * 0.04,
          width * 0.04,
          width * 0.04,
          0,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Get FREE delivery on every order!",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Delivery Pass from ₹99/month →",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  // ── INLINE COUPON SECTION ────────────────────────────────────────
  Widget _buildInlineCouponSection() {
    return Obx(() {
      final isApplied = couponController.appliedCode.value.isNotEmpty;
      final isLoading = couponController.isLoading.value;
      final error = couponController.couponMessage.value;

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

      // Not yet applied
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members only hint
          if (!passController.hasPass.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => Get.to(() => const PassPurchasePage()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.amber.shade700, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "Coupons available for Pass members only. Get Pass →",
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Coupon unlock progress for members
          if (passController.hasPass.value &&
              widget.totalAmount < passController.couponUnlockAt.value) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value:
                          widget.totalAmount /
                          passController.couponUnlockAt.value,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.green,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Add ₹${(passController.couponUnlockAt.value - widget.totalAmount).toStringAsFixed(0)} more to unlock coupons",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCtrl,
                  textCapitalization: TextCapitalization.characters,
                  enabled:
                      passController.hasPass.value &&
                      widget.totalAmount >= passController.couponUnlockAt.value,
                  decoration: InputDecoration(
                    hintText: !passController.hasPass.value
                        ? "Available for Pass members"
                        : widget.totalAmount <
                              passController
                                  .couponUnlockAt
                                  .value // ✅ fix 1
                        ? "Unlocks at ₹${passController.couponUnlockAt.value.toStringAsFixed(0)}"
                        : "Enter coupon code",
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
                  onPressed:
                      (isLoading ||
                          !passController.hasPass.value ||
                          widget.totalAmount <
                              passController.couponUnlockAt.value) // ✅ fix 2
                      ? null
                      : _applyCoupon,
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
      orderTotal: widget.totalAmount,
      totalQty: _totalQty,
    );
  }

  Widget _addressButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
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

  void _showAddAddressSheet(BuildContext context) {
    final fullAddressCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final nearestLandmarkCtrl = TextEditingController();

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
              _inputField("Nearest Landmark", nearestLandmarkCtrl),
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
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      city: cityCtrl.text,
                      state: stateCtrl.text,
                      pincode: pincodeCtrl.text,
                      nearestLandmark: nearestLandmarkCtrl.text,
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
