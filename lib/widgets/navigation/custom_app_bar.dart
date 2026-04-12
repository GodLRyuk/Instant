import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import 'package:instant_delivery/pages/profile/profile_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showCart;
  final bool showBackButton; // 👈 NEW

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSearch = true,
    this.showCart = true,
    this.showBackButton = false, // 👈 default false
    required bool isTransparent,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,

      title: Image.asset(
        'assets/images/logo_transperent.png',
        fit: BoxFit.cover,
        width: width * 0.25,
        height: 35,
      ),

      // ✅ CONDITIONAL LEADING
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Get.back(); // 👈 go back
              },
            )
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => const ProfilePage());
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(1.0),
                      child: Image.asset(
                        'assets/images/profileImg.jpg',
                        fit: BoxFit.fill,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),

      // ✅ GRADIENT
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF53D288), Color.fromARGB(255, 136, 198, 65)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      // ✅ ACTIONS
      actions: [
        if (showCart)
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: width * 0.06,
            ),
            onPressed: () {
              Get.to(() => CartPage());
            },
          ),
        SizedBox(width: width * 0.02),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
