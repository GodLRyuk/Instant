import 'package:get/get.dart';
import 'package:instant_delivery/bindings/auth_binding.dart';
import 'package:instant_delivery/pages/auth/register_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/home/home_page.dart';

class AppRoutes {
  static const loginPage = '/login';
  static const homePage = '/home';
  static const registerPage = '/register';

  static final routes = [
    GetPage(
      name: loginPage,
      page: () => LoginPage(),
      binding: AuthBinding(), // Inject controller
    ),
    GetPage(
      name: registerPage,
      page: () => RegisterPage(), // ✅ ADD THIS
    ),
    GetPage(
      name: homePage,
      page: () => HomePage(),
      // You can add HomeBinding() if needed
    ),
  ];
}