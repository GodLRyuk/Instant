import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/controllers/auth_controller.dart';
import 'package:instant_delivery/route/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = AuthController.instance;
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: AppRoutes.loginPage);
    }
    return null;
  }
}
