/// Representa uma musica lida de uma playlist do Spotify.
class Track {
  final String name;

  /// Nomes dos artistas separados por ", ".
  final String artists;
  final String? album;

  const Track({required this.name, required this.artists, this.album});

  /// Rotulo exibido na interface e nos relatorios.
  String get displayLabel => artists.isEmpty ? name : '$artists - $name';

  /// Consulta usada para buscar a faixa no YouTube.
  String get searchQuery => artists.isEmpty ? name : '$artists $name';

  /// Cria a faixa a partir do JSON retornado pela API do Spotify.
  factory Track.fromSpotifyJson(Map<String, dynamic> json) {
    final artists = (json['artists'] as List<dynamic>? ?? const [])
        .map((a) => a is Map<String, dynamic> ? a['name']?.toString() ?? '' : '')
        .where((n) => n.isNotEmpty)
        .join(', ');

    return Track(
      name: json['name']?.toString() ?? '',
      artists: artists,
      album: json['album'] is Map<String, dynamic>
          ? json['album']['name']?.toString()
          : null,
    );
  }
}
