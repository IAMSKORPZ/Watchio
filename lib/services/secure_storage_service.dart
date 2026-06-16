import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  // Use a prefix to avoid collisions with regular settings
  static const String _prefix = 'secure_v1_';

  String _providerPasswordKey(String providerId) =>
      '${_prefix}provider_$providerId.password';

  Future<void> saveProviderPassword(String providerId, String? password) async {
    final prefs = await SharedPreferences.getInstance();
    final value = password?.trim();
    final key = _providerPasswordKey(providerId);
    
    if (value == null || value.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value);
  }

  Future<String?> readProviderPassword(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_providerPasswordKey(providerId));
  }

  Future<void> deleteProviderPassword(String providerId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_providerPasswordKey(providerId));
  }

  Future<void> saveProviderSecret(
    String providerId,
    String name,
    String? value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_prefix}provider_$providerId.$name';
    
    if (value == null || value.trim().isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, value.trim());
  }

  Future<String?> readProviderSecret(String providerId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}provider_$providerId.$name');
  }
}
