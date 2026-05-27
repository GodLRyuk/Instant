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
      id: json['id'] ?? 0,
      fullAddress: json['full_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  /// 🔥 ADD THIS METHOD
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_address': fullAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'is_default': isDefault,
    };
  }

  @override
  String toString() {
    return 'AddressModel(id: $id, fullAddress: $fullAddress, city: $city, state: $state, pincode: $pincode, isDefault: $isDefault)';
  }
}