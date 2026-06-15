import 'package:get/get.dart';
import 'package:instant_delivery/models/product_model.dart'; // adjust to your model path

class WishlistController extends GetxController {
  final RxList<ProductModel> items = <ProductModel>[].obs;

  bool isWishlisted(int productId) {
    return items.any((p) => p.id == productId);
  }

  void toggle(ProductModel product) {
    if (isWishlisted(product.id)) {
      items.removeWhere((p) => p.id == product.id);
      Get.snackbar(
        'Removed',
        '${product.name} removed from wishlist',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      items.add(product);
      Get.snackbar(
        'Saved',
        '${product.name} added to wishlist',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
