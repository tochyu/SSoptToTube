import 'package:flutter/material.dart';

/// Tema visual do app.
///
/// Paleta inspirada no Spotify (verde #1DB954) e no YouTube (vermelho #FF0000),
/// com Material 3 e tema escuro como padrao.
class AppTheme {
  AppTheme._();

  /// Verde caracteristico do Spotify.
  static const Color spotifyGreen = Color(0xFF1DB954);

  /// Vermelho caracteristico do YouTube.
  static const Color youtubeRed = Color(0xFFFF0000);

  /// Verde escuro usado como seed dos esquemas de cor.
  static const Color _seed = Color(0xFF1DB954);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // Fundo quase-preto no modo escuro, aproximando o visual do Spotify.
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : null,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : scheme.surface,
        foregroundColor: isDark ? Colors.white : scheme.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
