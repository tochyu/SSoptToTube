/// Modos de velocidade da transferencia.
///
/// Cada modo controla os delays entre chamadas às APIs, para respeitar
/// rate limits e reduzir o risco de bloqueio temporario.
enum SpeedMode { fast, normal, slow }

extension SpeedModeX on SpeedMode {
  String get label => switch (this) {
        SpeedMode.fast => 'Rápido',
        SpeedMode.normal => 'Normal',
        SpeedMode.slow => 'Lento',
      };

  String get description => switch (this) {
        SpeedMode.fast =>
          'Menos delay entre requisições. Mais rápido, porém com maior risco de atingir limites da API.',
        SpeedMode.normal =>
          'Equilíbrio entre velocidade e segurança. Recomendado para a maioria dos usuários.',
        SpeedMode.slow =>
          'Delays maiores para evitar qualquer bloqueio da API. Ideal para playlists muito grandes.',
      };

  /// Delay antes de cada busca de musica no YouTube.
  Duration get searchDelay => switch (this) {
        SpeedMode.fast => const Duration(milliseconds: 200),
        SpeedMode.normal => const Duration(milliseconds: 600),
        SpeedMode.slow => const Duration(milliseconds: 1500),
      };

  /// Delay antes/depois de cada gravacao (insercao na playlist).
  Duration get writeDelay => switch (this) {
        SpeedMode.fast => const Duration(milliseconds: 300),
        SpeedMode.normal => const Duration(milliseconds: 800),
        SpeedMode.slow => const Duration(milliseconds: 2000),
      };

  static SpeedMode fromName(String? name) => switch (name) {
        'fast' => SpeedMode.fast,
        'slow' => SpeedMode.slow,
        _ => SpeedMode.normal,
      };

  String get storageName => name;
}
