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

        return data;
      } else {
        return {'data': response.data};
      }
    } on DioError catch (e) {
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
  }) async {
    final response = await _dio.post(
      "/orders/create/",
      data: {
        "items": items,
        "address_id": address_id,
        "total_amount": totalAmount,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
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
}
