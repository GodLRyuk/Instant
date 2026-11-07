import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/route/app_routes.dart';
import 'package:instant_delivery/services/biometric_service.dart';
import 'package:instant_delivery/services/secure_storage.dart';
import 'package:instant_delivery/widgets/buttons/custom_button.dart';
import '../../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController authController = AuthController.instance;

  final TextEditingController userNameController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Obx(
        () => authController.isLoading.value
            ? Center(child: CircularProgressIndicator())
            : Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF53D288),
                      Color.fromARGB(255, 136, 198, 65),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.08,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: screenHeight * 0.10),
                        Image.asset(
                          'assets/images/logo_transperent.png',
                          width: screenWidth * 1,
                          height: screenHeight * 0.25,
                          fit: BoxFit.contain,
                        ),
                        // SizedBox(height: screenHeight * 0.10),

                        // Username Field
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.002,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4, // softer shadow
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: userNameController,
                            decoration: InputDecoration(
                              hintText: 'User Name',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),

                        // Password Field
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.002,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.05),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: screenHeight * 0.065,
                          child: CustomButton(
                            text: 'Login',
                            color: const Color.fromARGB(
                              255,
                              42,
                              42,
                              42,
                            ), // lighter, brighter button
                            width: 200,
                            onPressed: () {
                              authController.login(
                                userNameController.text,
                                passwordController.text,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Register Text
                        TextButton(
                          onPressed: () {
                            Get.toNamed(AppRoutes.registerPage);
                          },
                          child: Text(
                            "Don't have an account? Register",
                            style: TextStyle(
                              color: Colors.white, // darker text for visibility
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        TextButton(
                          onPressed: authController.continueAsGuest,
                          child: Text(
                            'Continue as Guest',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.fingerprint,
                            size: 50,
                            color: Colors.white,
                          ),
                          onPressed: () async {
                            final biometric = BiometricService();
                            final isAuthenticated = await biometric
                                .authenticate();

                            if (!isAuthenticated) return;

                            final secureStorage = SecureStorage();

                            String? email = await secureStorage.read(
                              'saved_email',
                            );
                            String? password = await secureStorage.read(
                              'saved_password',
                            );

                            if (email != null && password != null) {
                              authController.login(email, password);
                            } else {
                              AppSnackbar.show(
                                "Error",
                                "No saved credentials found",
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
