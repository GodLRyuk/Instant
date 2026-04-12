import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/models/cart_model.dart';
import 'package:instant_delivery/services/api_service.dart';

class CartController extends GetxController {
  var isLoading = false.obs;
  var total = 0.0.obs;
  var cartList = <Cart>[].obs;
  var cart = Rxn<Cart>();
  var cartItems = [].obs;
  var isUpdating = false.obs;
  final ApiService _apiService = ApiService();

  /// Add product to cart
  Future<void> addToCart(int productId, int quantity) async {
    isLoading.value = true;
    try {
      final data = await _apiService.addToCart(productId, quantity);

      if (data.statusCode == 200) {
        Get.snackbar(
          "Success",
          data.data["message"],
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(10),
          borderRadius: 8,
          duration: Duration(seconds: 2),
        );
      } else {
        Get.snackbar(
          "Opps",
          data.data['error'],
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(10),
          borderRadius: 8,
          duration: Duration(seconds: 2),
        );
      }
    } on DioException catch (e) {
      String errorMessage = "Something went wrong";

      if (e.response != null) {
        final data = e.response!.data;

        // 🔥 Handle different response formats safely
        if (data is Map) {
          errorMessage = data["error"] ?? data["message"] ?? errorMessage;
        } else if (data is String) {
          errorMessage = data;
        }
      }

      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(10),
        borderRadius: 8,
        duration: Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCart() async {
    try {
      isLoading.value = true;
      final data = await _apiService.getCartItems();
      cart.value = data;
      cartItems.value = data.items;
    } catch (e) {
      print("Cart error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> removeFromCart(int productId) async {
    try {
      await ApiService().removeCartItems(productId);

      // ✅ Remove locally
      cartItems.removeWhere((item) => item.product_id == productId);
      await fetchCart();

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> updateQuantity(int productId, int quantity) async {
    try {
      isUpdating.value = true;

      final response = await ApiService().UpdateCartItems(productId, quantity);
      await Future.delayed(const Duration(seconds: 2));
      if (response != null && response.statusCode == 200) {
        await fetchCart();
        return true;
      } else {
        Get.snackbar("Error", "Failed to update cart");
        return false;
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
