import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/pages/profile/profile_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showSearch;
  final bool showCart;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showSearch = true,
    this.showCart = true, required bool isTransparent,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      // ✅ CENTER TITLE
      centerTitle: true,

      title: Image.asset(
                'assets/images/logo_transperent.png',
                fit: BoxFit.cover,
                width: width * 0.25,
                height: 35,
              ),

      // ✅ LEFT USER ICON
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white, // ✅ white border
              width: 2, // thickness
            ),
          ),
          child: GestureDetector(
            onTap: () {
            Get.to(() => const ProfilePage());
          },
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.asset(
                  'assets/images/profileImg.png',
                  fit: BoxFit.fill,
                  width: 35,
                  height: 35,
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
            colors: [
              Color(0xFF53D288),
              Color.fromARGB(255, 136, 198, 65),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),

      // ✅ RIGHT ACTIONS
      actions: [
        if (showSearch)
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: width * 0.06),
            onPressed: () {
              // add search action
            },
          ),

        if (showCart)
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: Colors.white,
              size: width * 0.06,
            ),
            onPressed: () {
              // add cart action
            },
          ),

        SizedBox(width: width * 0.02),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
