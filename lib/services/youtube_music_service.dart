import 'package:googleapis/youtube/v3.dart' as yt;

import '../core/exceptions.dart';
import '../models/track_model.dart';
import 'youtube_auth_service.dart';

/// Integracao com a YouTube Data API v3 (API oficial do Google).
///
/// O YouTube Music nao possui API publica propria; porem, playlists criadas
/// via YouTube Data API aparecem automaticamente no YouTube Music do usuario.
/// O fluxo e 100% legal e oficial:
///   1. search.list  -> encontra o video da musica (nome + artista);
///   2. playlists.insert -> cria a playlist com o mesmo nome;
///   3. playlistItems.insert -> adiciona os videos encontrados.
class YouTubeMusicService {
  YouTubeMusicService(this._auth);

  final YouTubeAuthService _auth;
  yt.YouTubeApi? _api;

  Future<yt.YouTubeApi> _getApi() async {
    if (_api != null) return _api!;
    final client = await _auth.authenticatedClient();
    if (client == null) {
      throw const NotAuthenticatedException('Não conectado ao Google.');
    }
    _api = yt.YouTubeApi(client);
    return _api!;
  }

  /// Executa uma chamada com tratamento de erros de cota/rate limit
  /// e uma retentativa automatica em erros temporarios de limite.
  Future<T> _guard<T>(Future<T> Function() action) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await action();
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('quotaExceeded') ||
            msg.contains('dailyLimitExceeded')) {
          throw const QuotaExceededException(
            'Cota diária da API do YouTube atingida. A cota padrão permite '
            'inserir cerca de 200 músicas por dia. Tente novamente amanhã '
            'ou solicite aumento de cota no Google Cloud Console.',
          );
        }
        if (msg.contains('userRateLimitExceeded') ||
            msg.contains('rateLimitExceeded')) {
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          throw const ApiRequestException(
            'Limite de requisições do YouTube atingido. Tente o modo '
            '"Lento" nas configurações.',
          );
        }
        rethrow;
      }
    }
    throw const ApiRequestException('Falha inesperada na API do YouTube.');
  }

  /// Procura uma playlist do usuario pelo nome exato.
  /// Usada para reutilizar playlists ja transferidas (opcao "so as que faltam").
  Future<String?> findPlaylistByName(String name) async {
    final api = await _getApi();
    final response = await _guard(
      () => api.playlists.list(
        const ['snippet'],
        mine: true,
        maxResults: 50,
      ),
    );
    for (final item in response.items ?? const <yt.Playlist>[]) {
      if (item.snippet?.title == name) return item.id;
    }
    return null;
  }

  /// Cria uma playlist privada com o mesmo nome da playlist do Spotify.
  Future<String> createPlaylist(String name) async {
    final api = await _getApi();
    final playlist = yt.Playlist()
      ..snippet = (yt.PlaylistSnippet()
        ..title = name
        ..description =
            'Playlist transferida do Spotify via SpotToTube.')
      ..status = (yt.PlaylistStatus()..privacyStatus = 'private');

    final created = await _guard(
      () => api.playlists.insert(playlist, const ['snippet', 'status']),
    );
    return created.id!;
  }

  /// Encontra a playlist pelo nome ou cria uma nova.
  Future<String> findOrCreatePlaylist(String name) async {
    final existing = await findPlaylistByName(name);
    return existing ?? await createPlaylist(name);
  }

  /// IDs dos videos ja presentes em uma playlist (para evitar duplicados).
  Future<Set<String>> getPlaylistVideoIds(String playlistId) async {
    final api = await _getApi();
    final ids = <String>{};
    String? pageToken;

    do {
      final response = await _guard(
        () => api.playlistItems.list(
          const ['contentDetails'],
          playlistId: playlistId,
          maxResults: 50,
          pageToken: pageToken,
        ),
      );
      for (final item in response.items ?? const <yt.PlaylistItem>[]) {
        final videoId = item.contentDetails?.videoId;
        if (videoId != null) ids.add(videoId);
      }
      pageToken = response.nextPageToken;
    } while (pageToken != null);

    return ids;
  }

  /// Busca a melhor correspondencia de video para a faixa.
  /// Retorna null quando nada razoavel e encontrado.
  Future<String?> searchVideo(Track track) async {
    final api = await _getApi();
    final response = await _guard(
      () => api.search.list(
        const ['snippet'],
        q: track.searchQuery,
        type: const ['video'],
        maxResults: 5,
      ),
    );

    final items = response.items ?? const <yt.SearchResult>[];
    if (items.isEmpty) return null;

    yt.SearchResult? best;
    var bestScore = -1.0;
    for (final item in items) {
      final score = _score(item, track);
      if (score > bestScore) {
        bestScore = score;
        best = item;
      }
    }
    return best?.id?.videoId;
  }

  /// Adiciona um video ao final da playlist no YouTube.
  Future<void> addTrackToPlaylist(String playlistId, String videoId) async {
    final api = await _getApi();
    final item = yt.PlaylistItem()
      ..snippet = (yt.PlaylistItemSnippet()
        ..playlistId = playlistId
        ..resourceId = (yt.ResourceId()
          ..kind = 'youtube#video'
          ..videoId = videoId));

    await _guard(() => api.playlistItems.insert(item, const ['snippet']));
  }

  /// Heuristica simples de relevancia:
  /// - proporcao de palavras da busca presentes no titulo/canal;
  /// - bonus para canais oficiais (Topic/VEVO/Official);
  /// - penalidade para covers, karaoke, lives, etc.
  double _score(yt.SearchResult item, Track track) {
    final title = (item.snippet?.title ?? '').toLowerCase();
    final channel = (item.snippet?.channelTitle ?? '').toLowerCase();

    final words = track.searchQuery
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2)
        .toSet();

    if (words.isEmpty) return 0.5;

    var hits = 0;
    for (final w in words) {
      if (title.contains(w) || channel.contains(w)) hits++;
    }
    var score = hits / words.length;

    if (channel.contains('topic') ||
        channel.contains('vevo') ||
        title.contains('official')) {
      score += 0.15;
    }

    const penalties = [
      'cover', 'karaoke', 'instrumental', 'reaction', '8d audio',
      'slowed', 'live', 'remix', 'nightcore',
    ];
    for (final bad in penalties) {
      if (title.contains(bad)) score -= 0.2;
    }

    return score;
  }
}
