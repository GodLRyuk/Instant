import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/config/app_config.dart';
import 'package:instant_delivery/pages/splash/splash_screen.dart';
import 'package:instant_delivery/services/notification_service.dart';
import 'package:instant_delivery/services/security_service.dart';
import 'package:instant_delivery/services/privacy_shield.dart';
import 'route/app_routes.dart';
import 'bindings/auth_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SplashScreen());

  // ✅ Load Environment Variables
  await dotenv.load(fileName: ".env");
  AppConfig.validateRuntimeConfiguration();

  // ✅ Initialize Firebase and Notifications
  await Firebase.initializeApp();
  await NotificationService.initialize();

  // ✅ Initialize Security Features
  await SecurityService.initializeScreenPrivacy();

  bool compromised = await SecurityService.isDeviceCompromised();
  if (compromised) {
    debugPrint("WARNING: Device is rooted or in developer mode!");
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // ✅ Set notification listeners here
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationService.onActionReceivedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PrivacyShield(
      child: GetMaterialApp(
        title: 'Delivery App',
        debugShowCheckedModeBanner: false,
        initialBinding: AuthBinding(),
        initialRoute: AppRoutes.loginPage,
        getPages: AppRoutes.routes,
      ),
    );
  }
}
