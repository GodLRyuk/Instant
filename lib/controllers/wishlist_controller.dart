import 'package:get/get.dart';
import 'package:instant_delivery/models/product_model.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/controllers/auth_controller.dart';

class WishlistController extends GetxController {
  final RxList<ProductModel> items = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  static final ApiService _api = ApiService();
  @override
  void onInit() {
    super.onInit();
    if (AuthController.instance.isLoggedIn.value) {
      _loadWishlist();
    }
  }

  Future<void> _loadWishlist() async {
    try {
      items.assignAll(await fetchWishlist());
    } catch (e) {
      print("Wishlist Error: $e");
    }
  }

  static Future<List<ProductModel>> fetchWishlist() async {
    final data = await _api.getWishlist();
    return data
        .map((e) => ProductModel.fromJson(e['product'] as Map<String, dynamic>))
        .toList();
  }

  bool isWishlisted(int productId) {
    return items.any((p) => p.id == productId);
  }

  Future<void> toggle(ProductModel product) async {
    if (!AuthController.instance.isLoggedIn.value) {
      return;
    }

    if (isWishlisted(product.id)) {
      // Optimistic update — remove immediately, revert on failure
      items.removeWhere((p) => p.id == product.id);
      final success = await _api.removeFromWishlist(product.id);
      if (!success) {
        items.add(product); // revert
        Get.snackbar('Error', 'Could not remove from wishlist');
      } else {
        Get.snackbar(
          'Removed',
          '${product.name} removed from wishlist',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } else {
      // Optimistic update — add immediately, revert on failure
      items.add(product);
      final success = await _api.addToWishlist(product.id);
      if (!success) {
        items.removeWhere((p) => p.id == product.id); // revert
        Get.snackbar('Error', 'Could not add to wishlist');
      } else {
        Get.snackbar(
          'Saved',
          '${product.name} added to wishlist',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}
