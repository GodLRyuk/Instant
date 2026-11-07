import 'package:instant_delivery/widgets/app_snackbar.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:instant_delivery/controllers/profile_controller.dart';
import 'package:instant_delivery/pages/profile/profile_otp.dart';
import 'package:instant_delivery/services/api_service.dart';
import 'package:instant_delivery/widgets/buttons/custom_button.dart';
import 'package:instant_delivery/widgets/navigation/custom_app_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileController profileController = Get.put(ProfileController());
  final ApiService _apiService = ApiService();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;
  File? selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    /// ✅ Prefill existing data
    final user = profileController.user;

    usernameController.text = user['username'] ?? '';
    emailController.text = user['email'] ?? '';
    phoneController.text = user['phone'] ?? '';
    addressController.text = user['address'] ?? '';
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Edit Profile",
        isTransparent: false,
        showBackButton: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255),
              Color.fromARGB(255, 255, 255, 255),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(height: height * 0.05),

                buildTextField("Username", usernameController),
                buildTextField("Email", emailController),
                buildTextField("Phone", phoneController),
                buildTextField("Address", addressController),
                GestureDetector(
                  onTap: pickImage,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // small rounded corners
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade200,
                          child: selectedImage != null
                              ? Image.file(selectedImage!, fit: BoxFit.cover)
                              : (profileController.user['profile_image'] != null
                                    ? Image.network(
                                        profileController.user['profile_image'],
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        "assets/images/profileImg.jpg",
                                        fit: BoxFit.cover,
                                      )),
                        ),
                      ),

                      /// Camera icon
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const SizedBox(height: 20),

                CustomButton(
                  text: "Update Profile",
                  color: Colors.black,
                  isLoading: isLoading,
                  onPressed: () async {
                    setState(() => isLoading = true);

                    try {
                      final newEmail = emailController.text.trim();
                      final oldEmail = profileController.user['email'];

                      final data = {
                        "username": usernameController.text.trim(),
                        "email": newEmail,
                        "phone": phoneController.text.trim(),
                        "address": addressController.text.trim(),
                      };

                      if (newEmail != oldEmail) {
                        await _apiService.requestEmailOtp(newEmail);

                        Get.to(
                          () => EmailOtpPage(data: data, image: selectedImage),
                        );
                      } else {
                        await _apiService.updateProfile(
                          data,
                          image: selectedImage,
                        );

                        await profileController.fetchProfile();

                        Get.back();
                        AppSnackbar.show("Success", "Profile updated");
                      }
                    } catch (e) {
                      AppSnackbar.show("Error", e.toString());
                    } finally {
                      setState(() => isLoading = false);
                    }
                  },
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 230, 229, 229),
          borderRadius: BorderRadius.circular(15),
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
          style: const TextStyle(color: Colors.black), // ✅ visible text
          decoration: inputDecoration(label),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      border: InputBorder.none, // ✅ remove default border
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
    );
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }
}
