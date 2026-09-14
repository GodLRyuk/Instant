import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:instant_delivery/controllers/order_controller.dart';
import 'package:instant_delivery/controllers/wishlist_controller.dart';
import 'package:instant_delivery/pages/cart/cart_page.dart';
import 'package:instant_delivery/pages/home/home_page.dart';
import 'package:instant_delivery/pages/orders/order_list_page.dart';
import 'package:instant_delivery/pages/profile/profile_page.dart';
import 'package:instant_delivery/pages/wishlist/wishlist_page.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  final bool isGuest;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
    this.isGuest = false,
  });

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  OrderController? orderController;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (!widget.isGuest) {
      _pages = [
        ProfilePage(),
        OrderPage(),
        HomePage(),
        WishlistPage(),
        CartPage(),
      ];
      orderController = Get.put(OrderController());
      Get.put(WishlistController());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.isGuest ? const HomePage() : _pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.menu, 0),
          _buildNavItem(Icons.local_shipping, 1),
          _buildNavItem(Icons.home, 2),
          _buildNavItem(Icons.favorite_border, 3),
          _buildNavItem(Icons.shopping_cart, 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (widget.isGuest && index != 2) {
          _showLoginRequired();
          return;
        }

        setState(() {
          _currentIndex = index;
        });

        if (index == 2) {
          orderController?.fetchOrders();
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF53D288) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            if (isSelected) ...[
              SizedBox(width: 6),
              Text(
                _getLabel(index),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLoginRequired() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: const Text('Please log in to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Get.toNamed('/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  String _getLabel(int index) {
    switch (index) {
      case 0:
        return "Menu";
      case 1:
        return "Orders";
      case 2:
        return "Home";
      case 3:
        return "Wishlist";
      case 4:
        return "Cart";
      default:
        return "";
    }
  }
}
