import 'package:dio/dio.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/services/log_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // ❌ Skip token for login & register
    if (options.path.contains('/customer-login') ||
        options.path.contains('/register')) {
      return handler.next(options);
    }

    // ✅ Add token for other APIs
    String? token = await _secureStorage.read('access_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // If we get a 401 Unauthorized, try to refresh the token
    if (err.response?.statusCode == 401) {
      final token = await _secureStorage.read('access_token');
      if (token == null || token.isEmpty) {
        return handler.next(err);
      }

      // ❌ Don't try to refresh if the error itself came from a login or refresh attempt
      if (err.requestOptions.path.contains('/customer-login') ||
          err.requestOptions.path.contains('/token-refresh')) {
        return handler.next(err);
      }

      LogService.d("401 detected, attempting silent token refresh...");

      // ✅ Attempt refresh
      final String? newToken = await ApiService().refreshToken();

      if (newToken != null && newToken.isNotEmpty) {
        LogService.d("Refresh successful, retrying original request.");

        // Update the header and retry the original request
        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newToken';

        try {
          // Use a clean Dio instance for the retry to avoid interceptor recursion
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        LogService.e("Refresh failed, session expired.");
      }
    }

    return handler.next(err);
  }
}
