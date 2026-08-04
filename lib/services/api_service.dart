import 'dart:io';

import 'package:dio/dio.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/models/address_model.dart';
import 'package:instant_delivery/models/cart_model.dart';
import 'package:instant_delivery/models/category_model.dart';
import 'package:instant_delivery/models/registration_model.dart';
import 'package:instant_delivery/models/user_model.dart';
import 'package:instant_delivery/services/interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      validateStatus: (status) {
        return true; // ✅ allow ALL responses (200, 400, 500, etc.)
      },
    ),
  );

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/accounts/customer-login/', // Try without trailing slash first
        data: LoginModel(email: email, password: password).toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.data is Map<String, dynamic>) {
        final data = response.data;

        final prefs = await SharedPreferences.getInstance();

        // ✅ Store tokens
        await prefs.setString('access_token', data['access'] ?? '');
        await prefs.setString('refresh_token', data['refresh'] ?? '');

        // ✅ User info
        await prefs.setInt('user_id', data['user_id'] ?? 0);
        await prefs.setString('email', data['email'] ?? '');
        await prefs.setString('phone', data['phone'] ?? '');
        await prefs.setString('role', data['role'] ?? '');
        await prefs.setString('profile_image', data['profile_image'] ?? '');

        final fcmToken = prefs.getString('fcm_token');
        if (fcmToken != null && fcmToken.isNotEmpty) {
          await saveDeviceToken(fcmToken);
        }

        return data;
      } else {
        return {'data': response.data};
      }
    } on DioException catch (e) {
      if (e.response != null) {
        // Safely get error message
        if (e.response!.data is Map<String, dynamic>) {
          return {'error': e.response!.data['message'] ?? 'Unknown error'};
        } else {
          return {'error': e.response!.data.toString()};
        }
      } else {
        return {'error': e.message};
      }
    } catch (e) {
      print('Other error: $e');
      return {'error': 'Unexpected error: $e'};
    }
  }

  Future<RegisterResponseModel> register(RegisterModel model) async {
    try {
      final response = await _dio.post(
        '/accounts/register/',
        data: model.toJson(),
      );

      if (response.statusCode == 201) {
        return RegisterResponseModel.fromJson(response.data);
      } else {
        throw Exception(response.data['error'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? e.message ?? 'Network error',
      );
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data, {File? image}) async {
    final formData = FormData.fromMap(data);

    if (image != null) {
      formData.files.add(
        MapEntry("profile_image", await MultipartFile.fromFile(image.path)),
      );
    }

    final response = await _dio.put(
      '/accounts/update-profile/',
      data: formData,
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update profile");
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String type,
    String? email,
    required String otp,
  }) async {
    final Map<String, dynamic> data = {"type": type, "otp": otp};

    // ✅ Only send email if it is required
    if (type == "register" && email != null) {
      data["email"] = email;
    }

    final response = await _dio.post('/accounts/verify-otp/', data: data);

    if (response.data is Map && response.data["error"] != null) {
      throw Exception(
        "${response.data["error"]}"
        "${response.data["attempts_left"] != null ? ' (Attempts left: ${response.data["attempts_left"]})' : ''}",
      );
    }

    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmailChangeOtp({
    required String otp,
  }) async {
    final response = await _dio.post(
      '/accounts/verify-email-change-otp/',
      data: {"otp": otp},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> requestEmailOtp(String email) async {
    final response = await _dio.post(
      '/accounts/request-email-otp/',
      data: {"email": email},
    );

    return response.data;
  }

  Future<Map<String, dynamic>> resendOtp(int userId) async {
    final response = await _dio.post(
      '/accounts/resend-otp/',
      data: {"user_id": userId},
    );
    return response.data;
  }

  Future<List<CategoryModel>> getCategory() async {
    try {
      final response = await _dio.get('/masters/categories/');

      if (response.statusCode == 200) {
        List data = response.data;

        return data.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        throw Exception("Failed to load categories");
      }
    } catch (e) {
      throw Exception("Category API error: $e");
    }
  }

  Future<List<dynamic>> getProducts({int page = 1}) async {
    final response = await _dio.get("/products/");

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to load products");
    }
  }

  ApiService() {
    _dio.interceptors.add(AuthInterceptor()); // ✅ Add here
  }

  // ================= NEW ARRIVALS =================
  Future<List<dynamic>> getNewArrivals() async {
    try {
      final response = await _dio.get('/products/new-arrivals/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "New arrivals error");
    }
  }

  // ================= RECOMMENDED =================
  Future<List<dynamic>> getRecommended() async {
    try {
      final response = await _dio.get('/products/recommended/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Recommended API error");
    }
  }

  Future<List<dynamic>> getProductsByCategory(String categoryId) async {
    try {
      final response = await _dio.get(
        '/products/category/$categoryId/products/',
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Category API error");
    }
  }

  Future<List<dynamic>> getAdvBanner() async {
    try {
      final response = await _dio.get('/masters/banners/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Banner API error");
    }
  }

  Future<List<dynamic>> getTopBanner() async {
    try {
      final response = await _dio.get('/masters/advbanners/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Banner API error");
    }
  }

  Future<dynamic> addToCart(int productId, int quantity) async {
    try {
      final response = await _dio.post(
        '/cart/add/',
        data: {"product_id": productId, "quantity": quantity},
      );

      return response;
    } on DioException catch (e) {
      // Access the response safely
      final errorMessage = e;
      print("Error: $errorMessage");

      throw Exception(errorMessage);
    }
  }

  Future<Cart> getCartItems() async {
    try {
      final response = await _dio.get('/cart/view/');
      return Cart.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Cart API error");
    }
  }

  Future<void> removeCartItems(int productId) async {
    final response = await _dio.post(
      "/cart/remove/",
      data: {"product_id": productId},
    );

    print("RES: ${response.data}");

    if (response.statusCode == 200 && response.data['success'] == true) {
      // ✅ Success case
      return;
    } else {
      throw Exception(response.data['message'] ?? "Failed to delete item");
    }
  }

  Future<dynamic> UpdateCartItems(int productId, int quantity) async {
    final response = await _dio.post(
      "/cart/update-cart-quantity/",
      data: {"product_id": productId, "quantity": quantity},
    );

    return response;
  }

  Future<List<AddressModel>> getAddresses() async {
    final response = await _dio.get("/addresses/list/");

    if (response.statusCode == 200) {
      final List data = response.data;

      return data.map((e) => AddressModel.fromJson(e)).toList();
    } else {
      throw Exception("Failed to fetch addresses");
    }
  }

  Future<void> addAddress({
    required String fullAddress,
    required String city,
    required String state,
    required String pincode,
  }) async {
    try {
      final response = await _dio.post(
        "/addresses/add/",
        data: {
          "full_address": fullAddress,
          "city": city,
          "state": state,
          "pincode": pincode,
        },
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception("Failed to add address");
      }
    } catch (e) {
      print("API Add Address Error: $e");
      rethrow;
    }
  }

  Future<Response<dynamic>> getProfile() async {
    try {
      final response = await _dio.get("/accounts/profile/");
      return response;
    } catch (e) {
      print("API Profile Error: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> getProductBysearch(String product) async {
    final response = await _dio.get("/products/?search=$product");

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception("Failed to load products");
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required List items,
    required dynamic address_id,
    required double totalAmount,
    required String paymentMethod,
    required String paymentStatus,
    String? couponCode,
    String? currentLat,
    String? currentLng,
    String deliveryType = 'ASAP', // 👈 add
    String? scheduledDate, // 👈 add
    String? scheduledSlotStart, // 👈 add
    String? scheduledSlotEnd, // 👈 add
  }) async {
    final response = await _dio.post(
      "/orders/create/",
      data: {
        "items": items,
        "address_id": address_id,
        "total_amount": totalAmount,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "delivery_type": deliveryType, // 👈 add
        if (couponCode != null && couponCode.isNotEmpty)
          "coupon_code": couponCode,
        if (currentLat != null) "current_lat": double.tryParse(currentLat),
        if (currentLng != null) "current_lng": double.tryParse(currentLng),
        "scheduled_date": ?scheduledDate, // 👈 add
        "scheduled_slot_start": ?scheduledSlotStart, // 👈 add
        "scheduled_slot_end": ?scheduledSlotEnd, // 👈 add
      },
    );
    return {"data": response.data, "statusCode": response.statusCode};
  }

  Future verifyPayment(Map<String, dynamic> data) async {
    final response = await _dio.post("/verify-payment/", data: data);

    return response.data;
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await _dio.get("/orders/");
      return response.data;
    } catch (e) {
      throw Exception("Failed to fetch orders: $e");
    }
  }

  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    final response = await _dio.get("/orders/$orderId/");
    return response.data;
  }

  Future<dynamic> getReviews(int productId) async {
    final response = await _dio.get("/products/$productId/reviews/");
    return response.data; // already JSON
  }

  Future<Map<String, dynamic>> validateCoupon({
    required String code,
    required double orderTotal,
  }) async {
    try {
      final response = await _dio.post(
        '/promotions/validate-coupon/',
        data: {'code': code, 'order_total': orderTotal},
      );

      final data = response.data as Map<String, dynamic>;

      // Backend returns { success: true, ... } or { error: "..." }
      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Invalid coupon.');
      }
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? e.message ?? 'Network error.',
      );
    }
  }

  Future<Map<String, dynamic>> getFlashSale() async {
    try {
      final response = await _dio.get('/products/flash-sale/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Flash sale API error");
    }
  }

  Future<List<dynamic>> getBundles() async {
    try {
      final response = await _dio.get('/products/bundles/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Bundles API error");
    }
  }

  Future<Map<String, dynamic>> validateOrder({
    required List items,
    required dynamic addressId,
    String? currentLat,
    String? currentLng,
  }) async {
    final response = await _dio.post(
      "/orders/validate/",
      data: {
        "items": items,
        "address_id": addressId,
        if (currentLat != null) "current_lat": double.tryParse(currentLat),
        if (currentLng != null) "current_lng": double.tryParse(currentLng),
      },
    );
    return {"data": response.data, "statusCode": response.statusCode};
  }

  // ================= WISHLIST =================
  Future<List<dynamic>> getWishlist() async {
    try {
      final response = await _dio.get('/wishlist/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Wishlist fetch error");
    }
  }

  Future<bool> addToWishlist(int productId) async {
    try {
      final response = await _dio.post(
        '/wishlist/',
        data: {"product_id": productId},
      );
      return response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Add to wishlist error");
    }
  }

  Future<bool> removeFromWishlist(int productId) async {
    try {
      final response = await _dio.delete(
        '/wishlist/',
        data: {"product_id": productId},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Remove wishlist error");
    }
  }

  Future<Map<String, dynamic>> purchasePass({required String planType}) async {
    try {
      final response = await _dio.post(
        '/promotions/pass/purchase/',
        data: {'plan_type': planType},
      );
      return {"data": response.data, "statusCode": response.statusCode};
    } on DioException catch (e) {
      throw Exception(e.response?.data['error'] ?? "Pass purchase failed");
    }
  }

  Future<Map<String, dynamic>> getPassStatus() async {
    try {
      final response = await _dio.get('/promotions/pass/status/');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['error'] ?? "Failed to fetch pass status",
      );
    }
  }

  Future<List<dynamic>> getDeliverySlots() async {
    try {
      final response = await _dio.get('/orders/slots/');
      if (response.statusCode == 200) {
        return response.data;
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Slots fetch error");
    }
  }

  Future<void> saveDeviceToken(String token) async {
    try {
      final response = await _dio.post(
        '/accounts/save-device-token/',
        data: {'fcm_token': token},
      );
      print('Token saved: ${response.data}');
    } on DioException catch (e) {
      print('Failed to save token: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _dio.post(
        "/products/$productId/reviews/",
        data: {"rating": rating, "comment": comment},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": response.data};
      } else {
        return {
          "success": false,
          "error": response.data is Map
              ? (response.data['message'] ??
                    response.data['error'] ??
                    "Failed to submit review")
              : "Failed to submit review",
        };
      }
    } on DioException catch (e) {
      return {
        "success": false,
        "error": e.response?.data is Map
            ? (e.response?.data['message'] ??
                  e.response?.data['error'] ??
                  "Network error")
            : (e.message ?? "Network error"),
      };
    }
  }
}
