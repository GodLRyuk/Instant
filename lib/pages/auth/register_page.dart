import 'package:flutter/material.dart';
import 'package:instant_delivery/models/registration_model.dart';
import 'package:instant_delivery/pages/auth/otp_page.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/widgets/buttons/custom_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final ApiService _apiService = ApiService();
  final first_nameController = TextEditingController();
  final last_nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController zipCodeController = TextEditingController();

  String selectedRole = 'CUSTOMER';
  bool isLoading = false;
  final Map<String, String> _fieldErrors = {};
  @override
  void dispose() {
    first_nameController.dispose();
    last_nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    addressController.dispose();
    zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF53D288), Color.fromARGB(255, 136, 198, 65)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.10),
                Text(
                  "Registration",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                buildTextField("First Name", first_nameController),
                buildTextField("Last Name", last_nameController),
                buildTextField("Username", usernameController),
                buildTextField("Email", emailController),
                buildTextField(
                  "Password",
                  passwordController,
                  isPassword: true,
                ),
                buildTextField("Phone", phoneController),
                buildTextField("Address", addressController),
                buildTextField("Zip Code", zipCodeController),
                const SizedBox(height: 15),
                CustomButton(
                  text: "Register",
                  color: Colors.black,
                  isLoading: isLoading, // ✅ important
                  onPressed: () async {
                    if (!_validateFields()) return;

                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final model = RegisterModel(
                        first_name: first_nameController.text.trim(),
                        last_name: last_nameController.text.trim(),
                        username: usernameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        phone: phoneController.text.trim(),
                        address: addressController.text.trim(),
                        role: "CUSTOMER",
                        zip_code: zipCodeController.text
                            .trim(), // Placeholder value
                      );

                      final result = await _apiService.register(model);

                      // if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtpPage(email: result.email),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll("Exception: ", ""),
                          ),
                        ),
                      );
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ), // darker text for visibility
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: const Color.fromARGB(
                            255,
                            0,
                            121,
                            181,
                          ), // darker text for visibility
                          fontSize: screenWidth * 0.04,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    final errorText = _fieldErrors[label];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: errorText == null
                  ? null
                  : Border.all(color: Colors.red.shade700),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              onChanged: (value) => _updateFieldError(label, value),
              style: const TextStyle(color: Colors.black), // ✅ visible text
              decoration: inputDecoration(label),
            ),
          ),
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _validateFields() {
    final fields = <String, String>{
      'First Name': first_nameController.text,
      'Last Name': last_nameController.text,
      'Username': usernameController.text,
      'Email': emailController.text,
      'Password': passwordController.text,
      'Phone': phoneController.text,
      'Address': addressController.text,
      'Zip Code': zipCodeController.text,
    };
    final errors = <String, String>{};

    fields.forEach((label, value) {
      final error = _fieldError(label, value);
      if (error != null) errors[label] = error;
    });

    setState(() {
      _fieldErrors
        ..clear()
        ..addAll(errors);
    });
    return errors.isEmpty;
  }

  void _updateFieldError(String label, String value) {
    final error = _fieldError(label, value);
    if (error == _fieldErrors[label]) return;

    setState(() {
      if (error == null) {
        _fieldErrors.remove(label);
      } else {
        _fieldErrors[label] = error;
      }
    });
  }

  String? _fieldError(String label, String value) {
    final trimmedValue = value.trim();

    switch (label) {
      case 'First Name':
        return trimmedValue.isEmpty ? 'First name is required.' : null;
      case 'Last Name':
        return trimmedValue.isEmpty ? 'Last name is required.' : null;
      case 'Username':
        if (trimmedValue.isEmpty) return 'Username is required.';
        if (RegExp(r'\s').hasMatch(value)) {
          return 'Username cannot contain spaces.';
        }
        return null;
      case 'Email':
        if (trimmedValue.isEmpty) return 'Email is required.';
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmedValue)) {
          return 'Enter a valid email address.';
        }
        return null;
      case 'Password':
        if (trimmedValue.isEmpty) return 'Password is required.';
        if (trimmedValue.length < 8) {
          return 'Password must be at least 8 characters.';
        }
        return null;
      case 'Phone':
        if (trimmedValue.isEmpty) return 'Phone number is required.';
        if (!RegExp(r'^\d{10}$').hasMatch(trimmedValue)) {
          return 'Enter a valid 10-digit phone number.';
        }
        return null;
      case 'Address':
        return trimmedValue.isEmpty ? 'Address is required.' : null;
      case 'Zip Code':
        if (trimmedValue.isEmpty) return 'PIN code is required.';
        if (!RegExp(r'^\d{6}$').hasMatch(trimmedValue)) {
          return 'Enter a valid 6-digit PIN code.';
        }
        return null;
      default:
        return null;
    }
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      border: InputBorder.none, // ✅ remove default border
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    );
  }
}
