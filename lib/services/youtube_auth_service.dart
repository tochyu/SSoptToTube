import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

import '../core/constants.dart';

/// Autenticacao OAuth 2.0 com Google/YouTube via google_sign_in.
///
/// O app solicita os escopos da YouTube Data API v3. No Android, o OAuth
/// client e resolvido automaticamente pelo package name + SHA-1 configurados
/// no Google Cloud Console (veja README.md).
class YouTubeAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: AppConstants.youtubeScopes,
  );

  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Abre o fluxo de login do Google. Retorna null se o usuario cancelar.
  Future<GoogleSignInAccount?> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser;
  }

  /// Restaura silenciosamente a sessao salva (ao abrir o app).
  Future<GoogleSignInAccount?> restore() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
    } catch (_) {
      _currentUser = null;
    }
    return _currentUser;
  }

  /// Desconecta a conta Google do app (revoga o acesso concedido).
  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
    _currentUser = null;
  }

  /// Cliente HTTP autenticado com o token da sessao Google atual,
  /// pronto para ser usado pelo YouTubeApi (googleapis).
  Future<http.Client?> authenticatedClient() =>
      _googleSignIn.authenticatedClient();
}
