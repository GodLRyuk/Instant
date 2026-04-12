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
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);

        // ✅ Store user info
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('email', data['email']);
        await prefs.setString('role', data['role']);

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

      return RegisterResponseModel.fromJson(response.data);
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
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
    final response = await _dio.get(
      "/addresses/list/",
    );

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
}
