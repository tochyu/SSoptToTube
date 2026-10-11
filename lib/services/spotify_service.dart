import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import 'spotify_auth_service.dart';

/// Cliente REST para a Web API oficial do Spotify (api.spotify.com).
///
/// Implementado com http puro para manter o controle total sobre
/// paginacao, headers e tratamento de rate limit (HTTP 429).
class SpotifyService {
  SpotifyService(this._auth);

  final SpotifyAuthService _auth;
  final http.Client _client = http.Client();

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// GET autenticado com renovacao automatica de token e retry em 429.
  Future<Map<String, dynamic>> _getJson(String url) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final token = await _auth.getValidAccessToken();
      if (token == null) {
        throw const NotAuthenticatedException('Não conectado ao Spotify.');
      }

      final response =
          await _client.get(Uri.parse(url), headers: _headers(token));

      // Rate limit: respeita o Retry-After informado pelo Spotify.
      if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 2;
        await Future.delayed(Duration(seconds: retryAfter + 1));
        continue;
      }

      if (response.statusCode == 401) {
        throw const NotAuthenticatedException(
          'Sessão do Spotify expirada. Reconecte na tela inicial.',
        );
      }

      if (response.statusCode != 200) {
        throw ApiRequestException(
          'Erro Spotify ${response.statusCode}: ${response.body}',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw const ApiRequestException(
      'Spotify: limite de requisições atingido repetidamente. '
      'Tente novamente no modo de velocidade "Lento".',
    );
  }

  /// Nome de exibicao do usuario autenticado.
  Future<String> getUserDisplayName() async {
    final data = await _getJson('https://api.spotify.com/v1/me');
    return data['display_name']?.toString() ?? 'Usuário Spotify';
  }

  /// Todas as playlists do usuario (e colaborativas), com paginacao.
  Future<List<SpotifyPlaylist>> getUserPlaylists() async {
    final playlists = <SpotifyPlaylist>[];
    String? next = 'https://api.spotify.com/v1/me/playlists?limit=50';

    while (next != null) {
      final data = await _getJson(next);
      final items = data['items'] as List<dynamic>? ?? const [];
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          playlists.add(SpotifyPlaylist.fromJson(item));
        }
      }
      next = data['next']?.toString();
    }
    return playlists;
  }

  /// Todas as faixas de uma playlist, com paginacao (100 por pagina).
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    final tracks = <Track>[];
    String? next =
        'https://api.spotify.com/v1/playlists/${Uri.encodeComponent(playlistId)}/tracks?limit=100&fields=next,items(track(id,name,artists(name),album(name)))';

    while (next != null) {
      final data = await _getJson(next);
      final items = data['items'] as List<dynamic>? ?? const [];
      for (final item in items) {
        final track =
            item is Map<String, dynamic> ? item['track'] : null;
        if (track is Map<String, dynamic>) {
          tracks.add(Track.fromSpotifyJson(track));
        }
      }
      next = data['next']?.toString();
    }
    return tracks;
  }

  void dispose() => _client.close();
}
