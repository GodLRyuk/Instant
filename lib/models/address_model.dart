class AddressModel {
  final int id;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      fullAddress: json['full_address'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }
}