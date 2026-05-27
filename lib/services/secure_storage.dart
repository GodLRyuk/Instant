import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Save data
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Read data
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Delete data
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}