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

  /// Add product to cart.
  /// Returns [true] on success (HTTP 200), [false] on any failure.
  Future<bool> addToCart(int productId, int quantity) async {
    isLoading.value = true;
    try {
      final data = await _apiService.addToCart(productId, quantity);

      if (data.statusCode == 200) {
        Get.snackbar(
          "Success",
          data.data["message"] ?? "Added to cart",
          backgroundColor: Colors.green.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(10),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
        return true; // ✅ success
      } else {
        Get.snackbar(
          "Oops",
          data.data['error'] ?? "Failed to add to cart",
          backgroundColor: Colors.red.shade600,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(10),
          borderRadius: 8,
          duration: const Duration(seconds: 2),
        );
        return false; // ❌ non-200 status
      }
    } on DioException catch (e) {
      String errorMessage = "Something went wrong";

      if (e.response != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage =
              responseData["error"] ?? responseData["message"] ?? errorMessage;
        } else if (responseData is String) {
          errorMessage = responseData;
        }
      }

      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
        duration: const Duration(seconds: 2),
      );
      return false; // ❌ exception
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
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> removeFromCart(int productId) async {
    try {
      await ApiService().removeCartItems(productId);
      cartItems.removeWhere((item) => item.product_id == productId);
      await fetchCart();
      return true;
    } catch (e) {
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
