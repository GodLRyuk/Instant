import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductController extends GetxController {
  static const _productsCacheKey = 'home_products_page_1';
  static const _bannersCacheKey = 'home_banners';
  static const _topBannersCacheKey = 'home_top_banners';

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
  final bool loadOnInit;
  bool _productsLoaded = false;
  bool _newArrivalsLoaded = false;
  bool _recommendedLoaded = false;
  bool _bannersLoaded = false;
  bool _topBannersLoaded = false;
  bool _flashSaleLoaded = false;
  ProductController({this.tagName, this.loadOnInit = true});

  /// 🔥 Scroll Controller
  final ScrollController scrollController = ScrollController();

  /// Flash Sale
  var flashSaleProducts = <ProductModel>[].obs;
  var flashSaleEndTime = Rxn<DateTime>();
  var flashSaleTitle = ''.obs;
  var isFlashSaleLoading = false.obs;

  @override
  void onInit() {
    if (loadOnInit) {
      fetchProducts();
      fetchNewArrivals();
      fetchRecommended();
      fetchBanners();
      fetchTopBanners();
      fetchFlashSale();
    }
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

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _productsLoaded) return;
      if (!forceRefresh && productList.isEmpty) {
        try {
          _productsLoaded = await _loadCachedProducts();
        } catch (error, stackTrace) {
          debugPrint("Ignoring invalid cached products: $error");
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      if (!forceRefresh && _productsLoaded) return;
      if (productList.isEmpty) isLoading(true);

      final response = await _apiService.getProducts();
      productList.value = response.products
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      currentPage = 1;
      hasMore = response.hasMore;
      _productsLoaded = true;
      await _saveCachedProducts(response.products, response.hasMore);
    } catch (e) {
      debugPrint("Product Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<bool> _loadCachedProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final cachedData = preferences.getString(_productsCacheKey);
    if (cachedData == null) return false;

    final decoded = jsonDecode(cachedData);
    if (decoded is! Map<String, dynamic> || decoded['products'] is! List) {
      throw const FormatException('Invalid cached products response');
    }

    productList.assignAll(
      (decoded['products'] as List)
          .map<ProductModel>(
            (item) => ProductModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
    hasMore = decoded['hasMore'] == true;
    return true;
  }

  Future<void> _saveCachedProducts(
    List<dynamic> products,
    bool hasMoreProducts,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _productsCacheKey,
      jsonEncode({'products': products, 'hasMore': hasMoreProducts}),
    );
  }

  Future<void> fetchNewArrivals({bool forceRefresh = false}) async {
    if (_newArrivalsLoaded && !forceRefresh) return;
    try {
      isLoading(true);

      final response = await _apiService.getNewArrivals();

      newArrivalList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      _newArrivalsLoaded = true;
    } catch (e) {
      print("New Arrival Error: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchRecommended({bool forceRefresh = false}) async {
    if (_recommendedLoaded && !forceRefresh) return;
    try {
      isLoading(true);

      final response = await _apiService.getRecommended();

      recommendedList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      _recommendedLoaded = true;
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
      currentPage = 1;
      hasMore = false;
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

  Future<void> fetchBanners({bool forceRefresh = false}) async {
    try {
      if (_bannersLoaded && !forceRefresh) return;
      if (!forceRefresh && bannerList.isEmpty) {
        _bannersLoaded = await _restoreCachedBannerList(_bannersCacheKey, bannerList);
      }
      if (_bannersLoaded && !forceRefresh) return;
      if (bannerList.isEmpty) isLoading(true);

      final response = await _apiService.getAdvBanner();

      bannerList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      await _saveCachedBannerList(_bannersCacheKey, response);
      _bannersLoaded = true;
    } catch (error, stackTrace) {
      debugPrint("Banner Error: $error");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading(false);
    }
  }

  Future<void> fetchTopBanners({bool forceRefresh = false}) async {
    try {
      if (_topBannersLoaded && !forceRefresh) return;
      if (!forceRefresh && topbannerList.isEmpty) {
        _topBannersLoaded = await _restoreCachedBannerList(_topBannersCacheKey, topbannerList);
      }
      if (_topBannersLoaded && !forceRefresh) return;
      if (topbannerList.isEmpty) isLoading(true);

      final response = await _apiService.getTopBanner();

      topbannerList.value = response
          .map<ProductModel>((e) => ProductModel.fromJson(e))
          .toList();
      await _saveCachedBannerList(_topBannersCacheKey, response);
      _topBannersLoaded = true;
    } catch (error, stackTrace) {
      debugPrint("Top banner error: $error");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading(false);
    }
  }

  Future<bool> _restoreCachedBannerList(
    String cacheKey,
    RxList<ProductModel> target,
  ) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cachedData = preferences.getString(cacheKey);
      if (cachedData == null) return false;

      final decoded = jsonDecode(cachedData);
      if (decoded is! List) {
        throw const FormatException('Invalid cached banner response');
      }

      target.assignAll(
        decoded
            .map<ProductModel>(
              (item) => ProductModel.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint("Unable to restore cached banners: $error");
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _saveCachedBannerList(
    String cacheKey,
    List<dynamic> banners,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(cacheKey, jsonEncode(banners));
  }

  Future<void> loadMoreProducts() async {
    if (isMoreLoading.value || !hasMore) return;

    try {
      isMoreLoading(true);

      final nextPage = currentPage + 1;
      final response = await _apiService.getProducts(page: nextPage);
      if (response.products.isNotEmpty) {
        productList.addAll(
          response.products
              .map<ProductModel>((e) => ProductModel.fromJson(e))
              .toList(),
        );
      }
      currentPage = nextPage;
      hasMore = response.hasMore;
    } catch (e) {
      debugPrint("Load More Error: $e");
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

  Future<void> fetchFlashSale({bool forceRefresh = false}) async {
    if (_flashSaleLoaded && !forceRefresh) return;
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
      _flashSaleLoaded = true;
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
        AppSnackbar.show(
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
