import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  String _providerPasswordKey(String providerId) =>
      'bingietv.provider.$providerId.password.v1';

  Future<void> saveProviderPassword(String providerId, String? password) async {
    final value = password?.trim();
    final key = _providerPasswordKey(providerId);
    if (value == null || value.isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<String?> readProviderPassword(String providerId) {
    return _storage.read(key: _providerPasswordKey(providerId));
  }

  Future<void> deleteProviderPassword(String providerId) {
    return _storage.delete(key: _providerPasswordKey(providerId));
  }

  Future<void> saveProviderSecret(
    String providerId,
    String name,
    String? value,
  ) async {
    final key = 'bingietv.provider.$providerId.$name.v1';
    if (value == null || value.trim().isEmpty) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: value.trim());
  }

  Future<String?> readProviderSecret(String providerId, String name) {
    return _storage.read(key: 'bingietv.provider.$providerId.$name.v1');
  }
}
