import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/address_controller.dart';
import 'package:instant_delivery/controllers/order_controller.dart';
import 'package:instant_delivery/controllers/profile_controller.dart';
import 'package:instant_delivery/pages/orders/order_detail_page.dart';
import 'package:instant_delivery/pages/orders/order_list_page.dart';
import 'package:instant_delivery/pages/profile/edit_profile_page.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController profileController = Get.put(ProfileController());
  final AddressController addressController = Get.put(AddressController());
  final OrderController ordercontroller = Get.put(OrderController());

  bool showAddresses = true;
  bool isFetched = false;
  bool showHelp = true;
  bool showOrders = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Profile Page",
        isTransparent: false,
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// ================= PROFILE HEADER =================
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  FutureBuilder<String?>(
                    future: _getProfileImage(),
                    builder: (context, snapshot) {
                      final image = snapshot.data;

                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: image != null && image.isNotEmpty
                            ? NetworkImage(image)
                            : const AssetImage("assets/images/profileImg.jpg")
                                  as ImageProvider,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  /// ✅ USERNAME
                  Obx(
                    () => Text(
                      (profileController.user['username'] ?? "User Name")
                          .toString()
                          .trim()
                          .split(' ')
                          .map(
                            (word) => word.isNotEmpty
                                ? word[0].toUpperCase() +
                                      word.substring(1).toLowerCase()
                                : '',
                          )
                          .join(' '),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  /// ✅ EMAIL (FIXED)
                  Obx(
                    () => Text(
                      profileController.user['email'] ?? "No Email",
                      style: const TextStyle(
                        color: Color.fromARGB(255, 86, 86, 86),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      Get.to(() => const EditProfilePage());
                    },
                    child: const Text("Edit Profile"),
                  ),
                ],
              ),
            ),
            const Divider(),

            /// ================= MENU =================
            _buildTile(Icons.shopping_bag, "My Orders", () {
              setState(() {
                showOrders = !showOrders;
              });

              if (showOrders) {
                ordercontroller.fetchOrders(); // if API call needed
              }
            }),
            showOrders
                ? Obx(() {
                    final orders = ordercontroller.orderList;

                    if (orders.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("No orders found"),
                      );
                    }

                    final limitedOrders = orders.take(3).toList();

                    return Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: limitedOrders.length,
                          itemBuilder: (context, index) {
                            final order = limitedOrders[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 5,
                              ),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Get.to(
                                    () => OrderDetailPage(orderId: order['id']),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.shopping_bag,
                                      color: Color(0xFF53D288),
                                      size: 20,
                                    ),

                                    SizedBox(width: 2),

                                    Expanded(
                                      child: Text(
                                        order['items'][0]['product_name'] ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        /// ================= SHOW MORE =================
                        if (orders.length > 3)
                          TextButton(
                            onPressed: () {
                              Get.to(() => OrderPage());
                            },
                            child: const Text(
                              "Show More",
                              style: TextStyle(color: Color(0xFF53D288)),
                            ),
                          ),
                      ],
                    );
                  })
                : const SizedBox(),

            /// ✅ ADDRESS TILE WITH TOGGLE
            _buildTile(Icons.location_on, "My Addresses", () {
              setState(() {
                showAddresses = !showAddresses;
              });

              if (showAddresses && !isFetched) {
                addressController.fetchAddresses();
                isFetched = true;
              }
            }, isExpanded: showAddresses),

            /// ✅ ADDRESS DROPDOWN
            showAddresses
                ? const SizedBox()
                : Obx(() {
                    if (addressController.addressList.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text("No addresses found"),
                      );
                    }
                    if (addressController.isLoading.value) {
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Column(
                      children: List.generate(
                        addressController.addressList.length,
                        (index) {
                          final address = addressController.addressList[index];

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 5,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_city,
                                  color: Color(0xFF53D288),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "${address.fullAddress}, ${address.city}, ${address.pincode}, ${address.state}",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  }),

            _buildTile(Icons.help, "Help & Support", () {
              setState(() {
                showHelp = !showHelp;
              });
            }, isExpanded: showHelp),
            showHelp
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.phone, color: Color(0xFF53D288)),
                            SizedBox(width: 10),
                            Text(
                              "Support Mobile:  +91 8670853699",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        Row(
                          children: [
                            Icon(Icons.email, color: Color(0xFF53D288)),
                            SizedBox(width: 10),
                            Text(
                              "Support Email:  support@instantdelivery.com",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        Row(
                          children: [
                            Icon(Icons.access_time, color: Color(0xFF53D288)),
                            SizedBox(width: 10),
                            Text(
                              "Working Hours:  6:00 AM - 11:00 PM",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

            const SizedBox(height: 10),

            /// ================= LOGOUT =================
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.snackbar("Logout", "Successfully logged out");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF53D288),
                  ),
                  child: Text("Logout", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= TILE =================
  Widget _buildTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isExpanded = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Icon(
        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
      ),
      onTap: onTap,
    );
  }

  Future<String?> _getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image');
  }
}

/// ================= STAT BOX =================
class _StatBox extends StatelessWidget {
  final String title;
  final String value;

  const _StatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
