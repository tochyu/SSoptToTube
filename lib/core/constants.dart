/// Constantes globais do aplicativo.
///
/// ATENCAO: voce precisa preencher o Client ID do Spotify antes de compilar.
/// Veja o passo a passo completo no arquivo README.md.
class AppConstants {
  AppConstants._();

  // ===========================================================================
  // SPOTIFY
  // ===========================================================================
  // 1. Crie um app em https://developer.spotify.com/dashboard
  // 2. Adicione o Redirect URI exatamente como abaixo:
  //      com.spottotube://oauth2redirect
  // 3. Cole o Client ID gerado aqui:
  static const String spotifyClientId = '29033d2e9c9b48babd389165ae69fec5';

  /// Redirect URI registrado no Dashboard do Spotify.
  /// O mesmo valor precisa estar no AndroidManifest.xml (intent-filter).
  static const String spotifyRedirectUri = 'com.spottotube://oauth2redirect';

  /// Escopos necessarios: apenas leitura de playlists e musicas salvos.
  static const List<String> spotifyScopes = [
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-library-read',
  ];

  // ===========================================================================
  // GOOGLE / YOUTUBE
  // ===========================================================================
  // No Google Cloud Console:
  // 1. Ative a "YouTube Data API v3"
  // 2. Crie um OAuth Client ID do tipo "Android" com:
  //      Package name: com.spottotube.app
  //      SHA-1: impressao digital do seu keystore (debug e/ou release)
  // Nenhum client ID precisa ser colado no codigo (o Android resolve
  // automaticamente pelo package name + SHA-1).
  static const List<String> youtubeScopes = [
    'https://www.googleapis.com/auth/youtube',
    'https://www.googleapis.com/auth/youtube.force-ssl',
  ];

  /// Nome do app exibido no launcher e na barra do sistema.
  static const String appName = 'SpotToTube';

  /// Versao exibida nas configuracoes.
  static const String appVersion = '1.0.0';
}
