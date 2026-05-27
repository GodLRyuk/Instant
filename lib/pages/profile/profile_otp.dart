import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:instant_delivery/services/api_service.dart';

class EmailOtpPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final File? image;

  const EmailOtpPage({
    super.key,
    required this.data,
    this.image,
  });

  @override
  State<EmailOtpPage> createState() => _EmailOtpPageState();
}

class _EmailOtpPageState extends State<EmailOtpPage> {
  final TextEditingController otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool isLoading = false;
  String errorMessage = "";

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF53D288), Color(0xFF88C641)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: w * 0.08),
              child: Column(
                children: [
                  SizedBox(height: h * 0.08),

                  const Icon(Icons.lock_outline,
                      size: 60, color: Colors.white),

                  SizedBox(height: h * 0.05),

                  const Text(
                    "OTP Verification",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "Enter the OTP sent to ${widget.data["email"]}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),

                  SizedBox(height: h * 0.06),

                  // OTP FIELD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        counterText: "",
                        border: InputBorder.none,
                        hintText: "------",
                      ),
                    ),
                  ),

                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  SizedBox(height: h * 0.04),

                  // VERIFY BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isLoading ? null : verifyOtp,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              "Verify OTP",
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("OTP resent")),
                      );
                    },
                    child: const Text(
                      "Didn't receive OTP? Resend",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> verifyOtp() async {
  if (otpController.text.trim().isEmpty) {
    setState(() {
      errorMessage = "Please enter OTP";
    });
    return;
  }

  setState(() {
    isLoading = true;
    errorMessage = "";
  });

  try {
    // ✅ Call API
    await _apiService.verifyEmailChangeOtp(
      otp: otpController.text.trim(),
    );

    // ⏳ HOLD LOADER FOR 4 SECONDS
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // ✅ RETURN SUCCESS
    Get.back(result: true);

  } catch (e) {
    setState(() {
      errorMessage = e.toString().replaceAll("Exception: ", "");
    });
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
}