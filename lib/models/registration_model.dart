class RegisterModel {
  String first_name;
  String last_name;
  String username;
  String email;
  String password;
  String phone;
  String address;
  String role;
  String zip_code;

  RegisterModel({
    required this.first_name,
    required this.last_name,
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.role,
    required this.zip_code,
  });

  Map<String, dynamic> toJson() {
    return {
      "first_name": first_name,
      "last_name": last_name,
      "username": username,
      "email": email,
      "password": password,
      "phone": phone,
      "address": address,
      "role": role,
      "zip_code": zip_code,
    };
  }
}

class RegisterResponseModel {
  final String message;
  final String email;

  RegisterResponseModel({required this.message, required this.email});

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      message: json['message'],
      email: json['email'],
    );
  }
}
