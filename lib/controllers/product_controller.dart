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

  var isLoading = false.obs;
  var isMoreLoading = false.obs;

  /// 🔥 Pagination
  int currentPage = 1;
  bool hasMore = true;

  /// 🔥 Scroll Controller
  final ScrollController scrollController = ScrollController();
  @override
  void onInit() {
    fetchProducts();
    fetchNewArrivals();
    fetchRecommended();
    fetchBanners();
    fetchTopBanners();
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

      final response = await _apiService.getProducts(); // ✅ correct API

      if (response != null) {
        productList.value = response
            .map<ProductModel>((e) => ProductModel.fromJson(e))
            .toList();
      }
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

      if (response != null) {
        recommendedList.value = response
            .map<ProductModel>((e) => ProductModel.fromJson(e))
            .toList();
      }
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

      if (response != null && response.isNotEmpty) {
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
}
