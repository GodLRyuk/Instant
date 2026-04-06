import 'package:dio/dio.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/models/category_model.dart';
import 'package:instant_delivery/models/registration_model.dart';
import 'package:instant_delivery/models/user_model.dart';
import 'package:instant_delivery/services/interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      // connectTimeout: const Duration(seconds: 5),
      // receiveTimeout: const Duration(seconds: 5),
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

  Future<List<dynamic>> getProducts() async {
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
      final response = await _dio.get('/products/category/$categoryId/products/');
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
}
