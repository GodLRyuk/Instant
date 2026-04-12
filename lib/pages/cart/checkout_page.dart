import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/pages/cart/payment_page.dart';
import 'package:instant_delivery/services/location_service.dart'
    as LocationService;
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutPage extends StatefulWidget {
  final double totalAmount;
  final List items;
  const CheckoutPage({
    super.key,
    required this.totalAmount,
    required this.items,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final AddressController addressController = Get.put(AddressController());

  String selectedPayment = "GPay";
  bool showAllItems = false;
  @override
  void initState() {
    super.initState();
    addressController.fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: const CustomAppBar(
        title: "My Cart",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Column(
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
                        colors: [Colors.green.shade400, Colors.green.shade700],
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
                            Icon(
                              Icons.location_on,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
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
                            return const Text("No Address Found");
                          }

                          return Column(
                            children: addressController.addressList.map((
                              address,
                            ) {
                              final isSelected =
                                  addressController.selectedAddress.value?.id ==
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
                                () {
                                  _showAddAddressSheet(context);
                                },
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

                        /// 🔥 Items List
                        /// 🔥 Items List with Show More
                        Column(
                          children: [
                            ...List.generate(
                              (showAllItems
                                  ? widget.items.length
                                  : widget.items.take(3).length),
                              (index) {
                                final item = showAllItems
                                    ? widget.items[index]
                                    : widget.items.take(3).toList()[index];

                                return Column(
                                  children: [
                                    /// ITEM ROW
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          /// IMAGE
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: Image.network(
                                              item["image"],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          /// DETAILS
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
                                                    fontWeight: FontWeight.w500,
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

                                          /// PRICE
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

                                    /// 🔥 Divider (not for last item)
                                    if (index !=
                                        (showAllItems
                                                ? widget.items.length
                                                : widget.items.take(3).length) -
                                            1)
                                      Divider(
                                        thickness: 0.8,
                                        color: Colors.grey.shade300,
                                        height: 16,
                                      ),
                                  ],
                                );
                              },
                            ),

                            /// SHOW MORE BUTTON
                            if (widget.items.length > 3)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    showAllItems = !showAllItems;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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

                        /// TOTAL
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total"),
                            Text(
                              "₹${widget.totalAmount}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                ],
              ),
            ),
          ),

          /// 🟢 BOTTOM BAR
          Container(
            padding: EdgeInsets.all(width * 0.02),
            width: width * 0.9,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (addressController.selectedAddress.value == null) {
                          Get.snackbar("Error", "Please select address");
                          return;
                        }

                        Get.to(
                          () => PaymentPage(
                            totalAmount: widget.totalAmount,
                            items: widget.items,
                            address: addressController.selectedAddress.value,
                          ),
                        );
                      },
                      child: const Text(
                        "Confirm Order",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 ADDRESS BUTTON
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

  /// 🔹 PAYMENT CARD
  Widget _paymentCard(String title, String value, IconData icon) {
    bool isSelected = selectedPayment == value;

    return GestureDetector(
      onTap: () => setState(() => selectedPayment = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: Icon(icon, color: Colors.green),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),

            if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  /// 🔥 ADD ADDRESS BOTTOM SHEET
  void _showAddAddressSheet(BuildContext context) {
    final TextEditingController fullAddressCtrl = TextEditingController();
    final TextEditingController cityCtrl = TextEditingController();
    final TextEditingController stateCtrl = TextEditingController();
    final TextEditingController pincodeCtrl = TextEditingController();

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
                onTap: () {
                  showLocationConfirm(fullAddressCtrl);
                },
              ),
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
                  child: Text(
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

  void showLocationConfirm(TextEditingController controller) {
    Get.defaultDialog(
      title: "Use Current Location?",
      middleText: "We will fetch your exact location",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        // 🔥 Show loader dialog
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        try {
          final data = await LocationService.getCurrentAddress();

          // close loader
          Get.back();

          // set value
          controller.text = data["fullAddress"]!;
        } catch (e) {
          Get.back(); // close loader if error

          Get.snackbar(
            "Error",
            "Failed to get location",
            snackPosition: SnackPosition.BOTTOM,
          );
        }

        // close confirm dialog
        Get.back();
      },
    );
  }

  Future<void> openUpiApp({
    required String upiId,
    required String name,
    required String amount,
    required String note,
  }) async {
    final String upiUrl =
        "upi://pay?pa=$upiId&pn=$name&am=$amount&cu=INR&tn=$note";

    final Uri uri = Uri.parse(upiUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar("Error", "No UPI app found on device");
    }
  }
}
