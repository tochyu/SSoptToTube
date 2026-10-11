import '../core/constants.dart';
import '../core/exceptions.dart';
import 'secure_storage_service.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// Autenticacao OAuth 2.0 com o Spotify usando AppAuth (Custom Tabs nativas).
///
/// Fluxo:
/// 1. [login] abre a tela de consentimento do Spotify e troca o codigo por tokens;
/// 2. Tokens sao salvos no flutter_secure_storage (persistem entre sessoes);
/// 3. [getValidAccessToken] renova automaticamente via refresh_token quando
///    o access token esta proximo de expirar.
class SpotifyAuthService {
  SpotifyAuthService(this._storage);

  final SecureStorageService _storage;
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  static const _clientId = AppConstants.spotifyClientId;
  static const _redirectUri = AppConstants.spotifyRedirectUri;

  static const _serviceConfiguration = AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://accounts.spotify.com/authorize',
    tokenEndpoint: 'https://accounts.spotify.com/api/token',
  );

  /// Indica se o desenvolvedor ja configurou o Client ID.
  bool get isConfigured =>
      _clientId.isNotEmpty && _clientId != 'SEU_SPOTIFY_CLIENT_ID';

  /// Executa o login. Retorna true se o usuario concluiu o fluxo
  /// e false se ele cancelou a tela de consentimento.
  Future<bool> login() async {
    if (!isConfigured) {
      throw const ApiRequestException(
        'Client ID do Spotify nao configurado. Edite lib/core/constants.dart '
        'e siga o README.md.',
      );
    }

    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          serviceConfiguration: _serviceConfiguration,
          scopes: AppConstants.spotifyScopes,
        ),
      );
      if (result.accessToken == null) return false;
      await _saveTokens(result);
      return true;
    } on FlutterAppAuthUserCancelledException {
      return false;
    } on FlutterAppAuthPlatformException catch (e) {
      throw ApiRequestException(
        'Falha no login do Spotify: ${e.message ?? e.code}',
      );
    }
  }

  /// Retorna um access token valido, renovando-o se necessario.
  /// Retorna null se nao houver sessao salva.
  Future<String?> getValidAccessToken() async {
    final access = await _storage.read(SecureStorageService.spotifyAccessToken);
    final expiryMs =
        int.tryParse(await _storage.read(SecureStorageService.spotifyTokenExpiry) ?? '');

    final isStillValid = access != null &&
        expiryMs != null &&
        DateTime.now().millisecondsSinceEpoch < expiryMs - 60000;

    if (isStillValid) return access;

    final refresh =
        await _storage.read(SecureStorageService.spotifyRefreshToken);
    if (refresh == null) return null;

    try {
      final refreshed = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          refreshToken: refresh,
          serviceConfiguration: _serviceConfiguration,
          scopes: AppConstants.spotifyScopes,
        ),
      );
      if (refreshed.accessToken == null) return null;
      await _saveTokens(refreshed);
      return refreshed.accessToken;
    } on FlutterAppAuthPlatformException {
      // Refresh token invalido/revogado: encerra a sessao local.
      await logout();
      return null;
    }
  }

  /// Limpa todos os dados da sessao Spotify.
  Future<void> logout() => _storage.deleteAll([
        SecureStorageService.spotifyAccessToken,
        SecureStorageService.spotifyRefreshToken,
        SecureStorageService.spotifyTokenExpiry,
        SecureStorageService.spotifyProfileName,
      ]);

  /// Nome do perfil salvo na ultima sessao (para restaurar estado da UI).
  Future<String?> cachedProfileName() =>
      _storage.read(SecureStorageService.spotifyProfileName);

  Future<void> cacheProfileName(String name) =>
      _storage.write(SecureStorageService.spotifyProfileName, name);

  /// Salva tokens de acesso/refresh e a data de expiracao em milissegundos.
  Future<void> _saveTokens(TokenResponse response) async {
    await _storage.write(
      SecureStorageService.spotifyAccessToken,
      response.accessToken!,
    );
    if (response.refreshToken != null) {
      await _storage.write(
        SecureStorageService.spotifyRefreshToken,
        response.refreshToken!,
      );
    }
    final expiry = response.accessTokenExpirationDateTime;
    if (expiry != null) {
      await _storage.write(
        SecureStorageService.spotifyTokenExpiry,
        expiry.millisecondsSinceEpoch.toString(),
      );
    }
  }
}
