import 'package:flutter/material.dart';

import '../models/playlist_model.dart';

/// Item da lista de playlists do Spotify com selecao multipla.
class PlaylistTile extends StatelessWidget {
  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.selected,
    required this.onToggle,
  });

  final SpotifyPlaylist playlist;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onToggle,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: playlist.imageUrl != null
              ? Image.network(
                  playlist.imageUrl!,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(context),
                )
              : _placeholder(context),
        ),
        title: Text(
          playlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${playlist.trackCount} músicas'
          '${playlist.owner != null && playlist.owner!.isNotEmpty ? ' • ${playlist.owner}' : ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Checkbox(
          value: selected,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
        width: 52,
        height: 52,
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Icon(Icons.queue_music),
      );
}
