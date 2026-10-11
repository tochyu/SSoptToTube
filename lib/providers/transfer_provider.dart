import 'package:flutter/foundation.dart';

import '../core/exceptions.dart';
import '../models/playlist_model.dart';
import '../models/speed_mode.dart';
import '../models/transfer_history_item.dart';
import '../services/history_service.dart';
import '../services/spotify_service.dart';
import '../services/youtube_music_service.dart';
import 'settings_provider.dart';

enum TransferStatus { idle, running, finished, cancelled, error }

/// Motor de transferencia: orquestra todo o fluxo
/// Spotify -> busca no YouTube -> criacao de playlist -> insercao de musicas,
/// publicando progresso em tempo real para a UI.
class TransferProvider extends ChangeNotifier {
  TransferProvider({
    required this.spotify,
    required this.youtube,
    required this.history,
    required this.settings,
  });

  final SpotifyService spotify;
  final YouTubeMusicService youtube;
  final HistoryService history;
  final SettingsProvider settings;

  TransferStatus status = TransferStatus.idle;
  List<SpotifyPlaylist> selected = const [];
  String? error;

  // --- Progresso em tempo real -------------------------------------------
  int playlistIndex = 0;
  int totalPlaylists = 0;
  String currentPlaylistName = '';
  int trackIndex = 0;
  int totalTracksCurrent = 0;
  String currentTrack = '';

  int added = 0;
  int notFound = 0;
  int skipped = 0;
  List<String> notFoundTracks = [];

  /// Relatorios por playlist da sessao atual (tambem salvos no historico).
  final List<TransferHistoryItem> sessionReports = [];

  bool _cancelRequested = false;
  bool get isRunning => status == TransferStatus.running;

  double get overallProgress {
    if (totalPlaylists == 0) return 0;
    final donePlaylists = playlistIndex.clamp(0, totalPlaylists);
    final currentFraction = totalTracksCurrent > 0
        ? (trackIndex / totalTracksCurrent).clamp(0.0, 1.0)
        : 0.0;
    return ((donePlaylists + currentFraction) / totalPlaylists)
        .clamp(0.0, 1.0);
  }

  void setSelected(List<SpotifyPlaylist> playlists) {
    selected = playlists;
    notifyListeners();
  }

  void requestCancel() => _cancelRequested = true;

  void reset() {
    status = TransferStatus.idle;
    error = null;
    playlistIndex = 0;
    totalPlaylists = 0;
    currentPlaylistName = '';
    trackIndex = 0;
    totalTracksCurrent = 0;
    currentTrack = '';
    added = 0;
    notFound = 0;
    skipped = 0;
    notFoundTracks = [];
    sessionReports.clear();
    notifyListeners();
  }

  /// Delay cancelavel: dividido em passos curtos para reagir ao botao cancelar.
  Future<void> _delay(Duration duration) async {
    const step = Duration(milliseconds: 100);
    var remaining = duration;
    while (remaining > Duration.zero && !_cancelRequested) {
      final chunk = remaining > step ? step : remaining;
      await Future<void>.delayed(chunk);
      remaining -= chunk;
    }
  }

  /// Executa a transferencia de todas as playlists selecionadas.
  Future<void> run() async {
    if (selected.isEmpty || isRunning) return;

    _cancelRequested = false;
    status = TransferStatus.running;
    error = null;
    added = 0;
    notFound = 0;
    skipped = 0;
    notFoundTracks = [];
    sessionReports.clear();
    totalPlaylists = selected.length;
    playlistIndex = 0;
    notifyListeners();

    try {
      for (var i = 0; i < selected.length; i++) {
        if (_cancelRequested) break;
        playlistIndex = i;
        final playlist = selected[i];
        currentPlaylistName = playlist.name;
        trackIndex = 0;
        totalTracksCurrent = 0;
        currentTrack = '';
        notifyListeners();

        // 1. Ler as musicas da playlist no Spotify.
        final tracks = await spotify.getPlaylistTracks(playlist.id);
        totalTracksCurrent = tracks.length;
        notifyListeners();

        // 2. Reutilizar a playlist no YouTube se ja existir, ou criar nova.
        final ytPlaylistId = await youtube.findOrCreatePlaylist(playlist.name);

        // 3. Se a opcao "so as que faltam" estiver ativa, carrega o que ja existe.
        final existingIds = settings.skipExisting
            ? await youtube.getPlaylistVideoIds(ytPlaylistId)
            : <String>{};

        var addedHere = 0;
        var missedHere = 0;
        var skippedHere = 0;

        for (final track in tracks) {
          if (_cancelRequested) break;
          currentTrack = track.displayLabel;
          trackIndex++;
          notifyListeners();

          final videoId =
              await youtube.searchVideo(track);
          await _delay(settings.speed.searchDelay);

          if (videoId == null) {
            notFound++;
            missedHere++;
            notFoundTracks.add(track.displayLabel);
          } else if (existingIds.contains(videoId)) {
            skipped++;
            skippedHere++;
          } else {
            await youtube.addTrackToPlaylist(ytPlaylistId, videoId);
            added++;
            addedHere++;
            await _delay(settings.speed.writeDelay);
          }
          notifyListeners();
        }

        sessionReports.add(TransferHistoryItem(
          playlistName: playlist.name,
          total: tracks.length,
          added: addedHere,
          notFound: missedHere,
          skipped: skippedHere,
          date: DateTime.now(),
        ));

        // Persiste no historico a cada playlist concluida
        // (progresso parcial nao se perde se o app for fechado).
        await history.addAll(sessionReports.sublist(sessionReports.length - 1));
      }

      status = _cancelRequested
          ? TransferStatus.cancelled
          : TransferStatus.finished;
    } on QuotaExceededException catch (e) {
      status = TransferStatus.error;
      error = e.message;
    } on NotAuthenticatedException catch (e) {
      status = TransferStatus.error;
      error = e.message;
    } on ApiRequestException catch (e) {
      status = TransferStatus.error;
      error = e.message;
    } catch (e) {
      status = TransferStatus.error;
      error = 'Erro inesperado: $e';
    }
    notifyListeners();
  }
}
