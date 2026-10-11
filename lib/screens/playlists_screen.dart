import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/playlist_model.dart';
import '../providers/auth_provider.dart';
import '../providers/transfer_provider.dart';
import '../services/spotify_service.dart';
import '../widgets/playlist_tile.dart';

/// Lista de playlists do Spotify com selecao multipla.
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late Future<List<SpotifyPlaylist>> _playlistsFuture;
  final Set<String> _selectedIds = {};
  late SpotifyService _spotifyService;
  List<SpotifyPlaylist> _playlists = const [];

  @override
  void initState() {
    super.initState();
    _spotifyService = _resolveSpotifyService();
    _playlistsFuture = _spotifyService.getUserPlaylists();
  }

  SpotifyService _resolveSpotifyService() {
    // O SpotifyService e criado no main e emprestado via AuthProvider.
    final auth = context.read<AuthProvider>();
    return auth.spotifyService;
  }

  void _retry() {
    setState(() => _playlistsFuture = _spotifyService.getUserPlaylists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suas playlists do Spotify')),
      body: FutureBuilder<List<SpotifyPlaylist>>(
        future: _playlistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar as playlists:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _retry,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final playlists = snapshot.data ?? const [];
          _playlists = playlists;
          if (playlists.isEmpty) {
            return const Center(
              child: Text('Nenhuma playlist encontrada no Spotify.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return PlaylistTile(
                playlist: playlist,
                selected: _selectedIds.contains(playlist.id),
                onToggle: () => setState(() {
                  if (!_selectedIds.add(playlist.id)) {
                    _selectedIds.remove(playlist.id);
                  }
                }),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            icon: const Icon(Icons.sync_alt),
            label: Text(
              _selectedIds.isEmpty
                  ? 'Selecione playlists para transferir'
                  : 'Transferir ${_selectedIds.length} playlist(s)',
            ),
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _startTransfer(context, _playlists),
          ),
        ),
      ),
    );
  }

  void _startTransfer(BuildContext context, List<SpotifyPlaylist> playlists) {
    final selected =
        playlists.where((p) => _selectedIds.contains(p.id)).toList();
    context.read<TransferProvider>().setSelected(selected);
    Navigator.pushNamed(context, '/transfer');
  }
}
