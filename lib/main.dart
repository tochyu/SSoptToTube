import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transfer_provider.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transfer_screen.dart';
import 'services/history_service.dart';
import 'services/secure_storage_service.dart';
import 'services/spotify_auth_service.dart';
import 'services/spotify_service.dart';
import 'services/youtube_auth_service.dart';
import 'services/youtube_music_service.dart';

void main() {
  runApp(const SpotToTubeApp());
}

/// Raiz do aplicativo.
///
/// Cria os singletons de servicos e providers e configura tema/rotas.
class SpotToTubeApp extends StatefulWidget {
  const SpotToTubeApp({super.key});

  @override
  State<SpotToTubeApp> createState() => _SpotToTubeAppState();
}

class _SpotToTubeAppState extends State<SpotToTubeApp> {
  late final ThemeProvider _themeProvider;
  late final SettingsProvider _settingsProvider;
  late final AuthProvider _authProvider;
  late final TransferProvider _transferProvider;
  late final HistoryService _historyService;

  @override
  void initState() {
    super.initState();

    // --- Singletons de servicos ---
    final secureStorage = SecureStorageService();
    final historyService = HistoryService();

    final spotifyAuth = SpotifyAuthService(secureStorage);
    final spotifyService = SpotifyService(spotifyAuth);
    final googleAuth = YouTubeAuthService();
    final youtubeService = YouTubeMusicService(googleAuth);

    // --- Providers ---
    _themeProvider = ThemeProvider()..load();
    _settingsProvider = SettingsProvider()..load();
    _authProvider = AuthProvider(
      spotifyAuth: spotifyAuth,
      spotifyService: spotifyService,
      googleAuth: googleAuth,
    )..restoreSessions();
    _transferProvider = TransferProvider(
      spotify: spotifyService,
      youtube: youtubeService,
      history: historyService,
      settings: _settingsProvider,
    );

    _historyService = historyService;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _transferProvider),
        Provider<HistoryService>.value(value: _historyService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'SpotToTube',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.mode,
          supportedLocales: const [Locale('pt', 'BR')],
          initialRoute: '/',
          routes: {
            '/': (_) => const HomeScreen(),
            '/playlists': (_) => const PlaylistsScreen(),
            '/transfer': (_) => const TransferScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/history': (_) => const HistoryScreen(),
          },
        ),
      ),
    );
  }
}
