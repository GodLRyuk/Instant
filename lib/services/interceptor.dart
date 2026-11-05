import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/auth_controller.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/log_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.path.contains('/customer-login') ||
        options.path.contains('/register')) {
      return handler.next(options);
    }

    var token = await _secureStorage.read('access_token');
    if (token == null || token.isEmpty) {
      try {
        token = await ApiService().refreshToken();
      } catch (error) {
        LogService.e('Unable to restore the access token', error: error);
      }
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (err.requestOptions.path.contains('/customer-login') ||
        err.requestOptions.path.contains('/token-refresh')) {
      return handler.next(err);
    }

    final token = await _secureStorage.read('access_token');
    if (token == null || token.isEmpty) {
      return handler.next(err);
    }

    LogService.d('401 detected, attempting silent token refresh...');

    String? newToken;
    try {
      newToken = await ApiService().refreshToken();
    } catch (e) {
      LogService.e('Unable to refresh the session', error: e);
      return handler.next(err);
    }

    if (newToken == null || newToken.isEmpty) {
      LogService.e('Refresh failed, session expired.');
      if (Get.isRegistered<AuthController>()) {
        await Get.find<AuthController>().logout();
      } else {
        await _secureStorage.delete('access_token');
        await _secureStorage.delete('refresh_token');
      }
      return handler.next(err);
    }

    LogService.d('Refresh successful, retrying original request.');
    final options = err.requestOptions;
    options.headers['Authorization'] = 'Bearer $newToken';

    try {
      final response = await Dio().fetch(options);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }
}
