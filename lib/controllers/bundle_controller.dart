import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:instant_delivery/controllers/cart_controller.dart';
import '../models/bundle_model.dart';
import '../services/api_service.dart';

class BundleController extends GetxController {
  final ApiService _apiService = ApiService();
  var bundleList = <BundleModel>[].obs;
  var isLoading = false.obs;
  final bool loadOnInit;

  BundleController({this.loadOnInit = true});

  @override
  void onInit() {
    if (loadOnInit) fetchBundles();
    super.onInit();
  }

  Future<void> fetchBundles() async {
    try {
      isLoading(true);
      final response = await _apiService.getBundles();
      bundleList.value = response.map((e) => BundleModel.fromJson(e)).toList();
    } catch (e) {
      bundleList.clear();
      print("Bundles Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> addBundleToCart(BundleModel bundle) async {
    try {
      await Future.wait(
        bundle.products.map((product) => _apiService.addToCart(product.id, 1)),
      );

      // ✅ Refresh cart so CartPage reflects the new items
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().fetchCart();
      }

      Get.snackbar(
        'Added to Cart',
        '${bundle.name} products added successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add bundle: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
