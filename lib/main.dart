import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'route/app_routes.dart';
import 'bindings/auth_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Delivery App',
      debugShowCheckedModeBanner: false,
      initialBinding: AuthBinding(), 
      initialRoute: AppRoutes.loginPage,
      getPages: AppRoutes.routes, 
    );
  }
}