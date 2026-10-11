import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper do flutter_secure_storage.
///
/// No Android usa EncryptedSharedPreferences, garantindo que tokens e dados
/// de sessao fiquem persistidos e protegidos no dispositivo.
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Chaves conhecidas
  static const spotifyAccessToken = 'spotify_access_token';
  static const spotifyRefreshToken = 'spotify_refresh_token';
  static const spotifyTokenExpiry = 'spotify_token_expiry';
  static const spotifyProfileName = 'spotify_profile_name';

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll(Iterable<String> keys) async {
    for (final key in keys) {
      await _storage.delete(key: key);
    }
  }
}
