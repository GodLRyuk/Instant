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
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  final secureStorage = SecureStorage();
  final accessToken = await secureStorage.read('access_token');
  final refreshToken = await secureStorage.read('refresh_token');
  var hasSavedSession = false;

  final savedEmail = await secureStorage.read('saved_email');
  final savedPassword = await secureStorage.read('saved_password');
  if (savedEmail != null &&
      savedEmail.isNotEmpty &&
      savedPassword != null &&
      savedPassword.isNotEmpty) {
    try {
      final loginResult = await ApiService().login(savedEmail, savedPassword);
      final loginAccessToken = loginResult['access'];
      final loginRefreshToken = loginResult['refresh'];
      hasSavedSession =
          !loginResult.containsKey('error') &&
          loginAccessToken is String &&
          loginAccessToken.isNotEmpty &&
          loginRefreshToken is String &&
          loginRefreshToken.isNotEmpty;
    } catch (e) {
      LogService.e('Automatic login with saved credentials failed', error: e);
    }
  }

  if (!hasSavedSession && refreshToken != null && refreshToken.isNotEmpty) {
    try {
      hasSavedSession = await ApiService().refreshToken() != null;
    } catch (e) {
      LogService.e('Could not restore the saved session at startup', error: e);
      // Leave saved credentials available for the next launch/retry.
    }

    if (!hasSavedSession &&
        (await secureStorage.read('refresh_token')) == refreshToken) {
      await secureStorage.delete('access_token');
      await secureStorage.delete('refresh_token');
    }
  } else if (accessToken != null && accessToken.isNotEmpty) {
    await secureStorage.delete('access_token');
  }

  runApp(
    MyApp(
      hasSeenOnboarding: hasSeenOnboarding,
      hasSavedSession: hasSavedSession,
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool hasSeenOnboarding;
  final bool hasSavedSession;

  const MyApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasSavedSession,
  });

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
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF303030),
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        initialBinding: AuthBinding(
          initialIsLoggedIn: widget.hasSavedSession,
        ),
        initialRoute: widget.hasSeenOnboarding
            ? widget.hasSavedSession
                  ? AppRoutes.dashboardPage
                  : AppRoutes.loginPage
            : AppRoutes.onboardingPage,
        getPages: AppRoutes.routes,
      ),
    );
  }
}
