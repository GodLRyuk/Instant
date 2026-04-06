class RegisterModel {
  String username;
  String email;
  String password;
  String phone;
  String address;
  String role;

  RegisterModel({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "password": password,
      "phone": phone,
      "address": address,
      "role": role,
    };
  }
}
class RegisterResponseModel {
  final String message;

  RegisterResponseModel({required this.message});

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json['message'] ?? "Registration successful",
    );
  }
}