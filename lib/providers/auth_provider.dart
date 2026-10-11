import 'package:flutter/foundation.dart';

import '../services/spotify_auth_service.dart';
import '../services/spotify_service.dart';
import '../services/youtube_auth_service.dart';

/// Estado das contas conectadas (Spotify e Google/YouTube).
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this.spotifyAuth,
    required this.spotifyService,
    required this.googleAuth,
  });

  final SpotifyAuthService spotifyAuth;
  final SpotifyService spotifyService;
  final YouTubeAuthService googleAuth;

  bool spotifyBusy = false;
  bool googleBusy = false;

  String? spotifyUser;
  String? googleEmail;

  bool get spotifyConnected => spotifyUser != null;
  bool get googleConnected => googleEmail != null;
  bool get bothConnected => spotifyConnected && googleConnected;

  /// Restaura as sessoes salvas ao abrir o app.
  Future<void> restoreSessions() async {
    try {
      final token = await spotifyAuth.getValidAccessToken();
      spotifyUser =
          token != null ? await spotifyAuth.cachedProfileName() : null;
    } catch (_) {
      spotifyUser = null;
    }

    final account = await googleAuth.restore();
    googleEmail = account?.email;
    notifyListeners();
  }

  /// Login OAuth com Spotify. Erros propagam para a UI exibir feedback.
    /// Login OAuth com Spotify. Retorna true se conectou de verdade,
  /// false se o usuario cancelou. Erros propagam para a UI.
  Future<bool> connectSpotify() async {
    spotifyBusy = true;
    notifyListeners();
    try {
      final ok = await spotifyAuth.login();
      if (ok) {
        final name = await spotifyService.getUserDisplayName();
        await spotifyAuth.cacheProfileName(name);
        spotifyUser = name;
      }
      return ok;
    } finally {
      spotifyBusy = false;
      notifyListeners();
    }
  }

    spotifyBusy = true;
    notifyListeners();
    try {
      final ok = await spotifyAuth.login();
      if (ok) {
        final name = await spotifyService.getUserDisplayName();
        await spotifyAuth.cacheProfileName(name);
        spotifyUser = name;
      }
    } finally {
      spotifyBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnectSpotify() async {
    await spotifyAuth.logout();
    spotifyUser = null;
    notifyListeners();
  }

  /// Login OAuth com Google/YouTube. Retorna false se o usuario cancelou.
  Future<bool> connectGoogle() async {
    googleBusy = true;
    notifyListeners();
    try {
      final account = await googleAuth.signIn();
      googleEmail = account?.email;
      return googleEmail != null;
    } finally {
      googleBusy = false;
      notifyListeners();
    }
  }

  Future<void> disconnectGoogle() async {
    await googleAuth.signOut();
    googleEmail = null;
    notifyListeners();
  }
}
