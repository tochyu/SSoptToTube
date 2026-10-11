/// Playlist do usuario no Spotify.
class SpotifyPlaylist {
  final String id;
  final String name;
  final int trackCount;
  final String? imageUrl;
  final String? owner;

  const SpotifyPlaylist({
    required this.id,
    required this.name,
    required this.trackCount,
    this.imageUrl,
    this.owner,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List<dynamic>?;
    String? url;
    if (images != null && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) url = first['url']?.toString();
    }

    final tracks = json['tracks'];
    int count = 0;
    if (tracks is Map<String, dynamic>) {
      count = (tracks['total'] as num?)?.toInt() ?? 0;
    }

    final owner = json['owner'];
    final ownerName =
        owner is Map<String, dynamic> ? owner['display_name']?.toString() : null;

    return SpotifyPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Sem nome',
      trackCount: count,
      imageUrl: url,
      owner: ownerName,
    );
  }
}
