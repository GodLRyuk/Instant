import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductController extends GetxController {
  final ApiService _apiService = ApiService();

  var productList = <ProductModel>[].obs;
  var newArrivalList = <ProductModel>[].obs;
  var recommendedList = <ProductModel>[].obs;
  var bannerList = <ProductModel>[].obs;
  var topbannerList = <ProductModel>[].obs;
  RxInt currentProductId = 0.obs;
  RxDouble averageRating = 0.0.obs;
  RxInt reviewCount = 0.obs;
  final RxBool isSubmittingReview = false.obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var productListBackup = [].obs;
  RxList reviews = <dynamic>[].obs;

  /// 🔥 Pagination
  int currentPage = 1;
  bool hasMore = true;
  final String? tagName;
  ProductController({this.tagName});

  /// 🔥 Scroll Controller
  final ScrollController scrollController = ScrollController();

  /// Flash Sale
  var flashSaleProducts = <ProductModel>[].obs;
  var flashSaleEndTime = Rxn<DateTime>();
  var flashSaleTitle = ''.obs;
  var isFlashSaleLoading = false.obs;

  @override
  void onInit() {
    fetchProducts();
    fetchNewArrivals();
    fetchRecommended();
    fetchBanners();
    fetchTopBanners();
    fetchFlashSale();
    scrollController.addListener(_scrollListener);
    super.onInit();
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isMoreLoading.value &&
        hasMore) {
      loadMoreProducts();
    }
  }

  Future<void> fetchProducts() async {
    try {
      isLoading(true);

      final response = await _apiService.getProducts();
      productList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      print("Product Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchNewArrivals() async {
    try {
      isLoading(true);

      final response = await _apiService.getNewArrivals();

      newArrivalList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      print("New Arrival Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRecommended() async {
    try {
      isLoading(true);

      final response = await _apiService.getRecommended();

      recommendedList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      print("Recommended Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchProductsByCategory(String categoryID) async {
    isLoading(true);
    try {
      var response = await ApiService().getProductsByCategory(categoryID);
      productList.value = response
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchNewArrivalsByCategory(String categoryID) async {
    isLoading(true);
    try {
      var response = await ApiService().getProductsByCategory(categoryID);
      newArrivalList.value = response
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRecommendedByCategory(String categoryID) async {
    isLoading(true);
    try {
      var response = await ApiService().getProductsByCategory(categoryID);
      recommendedList.value = response
          .map((e) => ProductModel.fromJson(e))
          .toList();
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchBanners() async {
    try {
      isLoading(true);

      final response = await _apiService.getAdvBanner();

      bannerList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      print("New Arrival Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTopBanners() async {
    try {
      isLoading(true);

      final response = await _apiService.getTopBanner();

      topbannerList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
    } catch (e) {
      print("New Arrival Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadMoreProducts() async {
    try {
      isMoreLoading(true);

      currentPage++;

      final response = await _apiService.getProducts(page: currentPage);

      if (response.isNotEmpty) {
        productList.addAll(
          response.map<ProductModel>((e) => ProductModel.fromJson(e)).toList(),
        );
      } else {
        hasMore = false;
      }
    } catch (e) {
      print("Load More Error: $e");
    } finally {
      isMoreLoading(false);
    }
  }

  Future<void> filterBySearch(String product) async {
    isLoading(true);

    final response = await _apiService.getProductBysearch(product);

    final data = response
        .map<ProductModel>((e) => ProductModel.fromJson(e))
        .toList();

    productList.assignAll(data); // ✅ UI list
    productListBackup.assignAll(data); // ✅ optional backup

    isLoading(false);
  }

  Future<void> loadProductReviews(int productId) async {
    currentProductId.value = productId;

    await fetchReviews(productId);
  }

  Future<void> fetchReviews(int productId) async {
    try {
      reviews
          .clear(); // avoid showing stale reviews from the previous product while the new fetch is in flight
      final response = await _apiService.getReviews(productId);

      List<dynamic> reviewList;
      if (response is List) {
        reviewList = response;
      } else if (response is Map && response['results'] is List) {
        reviewList = response['results'];
      } else if (response is Map && response['reviews'] is List) {
        reviewList = response['reviews'];
      } else {
        reviewList = [];
      }

      reviews.value = List<dynamic>.from(reviewList);
      _calculateAverageRating();
    } catch (e) {
      print("Review error: $e");
      reviews.clear();
      _calculateAverageRating();
    }
  }

  void _calculateAverageRating() {
    if (reviews.isNotEmpty) {
      double total = 0;

      for (var r in reviews) {
        total += (r['rating'] ?? 0);
      }

      reviewCount.value = reviews.length; // 🔢 total reviews
      averageRating.value = total / reviews.length; // ⭐ average
    } else {
      reviewCount.value = 0;
      averageRating.value = 0.0;
    }
  }

  Future<void> fetchFlashSale() async {
    try {
      isFlashSaleLoading(true);
      final response = await _apiService.getFlashSale();

      if (response['flash_sale'] != null) {
        flashSaleTitle.value = response['flash_sale']['title'] ?? 'Flash Sale';
        flashSaleEndTime.value = DateTime.parse(
          response['flash_sale']['end_time'],
        ).toLocal();
        flashSaleProducts.value = (response['products'] as List)
            .map((e) => ProductModel.fromJson(e))
            .toList();
      } else {
        flashSaleProducts.clear();
        flashSaleEndTime.value = null;
      }
    } catch (e) {
      print("Flash Sale Error: $e");
    } finally {
      isFlashSaleLoading(false);
    }
  }

  Future<bool> submitReview(int productId, int rating, String comment) async {
    isSubmittingReview.value = true;
    try {
      final result = await ApiService().submitReview(
        productId: productId,
        rating: rating,
        comment: comment,
      );

      if (result['success'] == true) {
        await loadProductReviews(productId); // refresh list + average rating
        return true;
      } else {
        Get.snackbar(
          "Couldn't submit review",
          result['error'] ?? "Please try again",
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } finally {
      isSubmittingReview.value = false;
    }
  }
}
