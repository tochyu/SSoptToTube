import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_status_card.dart';

/// Tela inicial: status das conexoes e ponto de partida da transferencia.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SpotToTube')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.sync_alt,
                        color: theme.colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transfira suas playlists do Spotify para o YouTube '
                        'Music de forma legal, usando as APIs oficiais. '
                        'Nenhuma música é baixada.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            LoginStatusCard(
              title: 'Spotify',
              icon: Icons.graphic_eq,
              color: AppTheme.spotifyGreen,
              connected: auth.spotifyConnected,
              busy: auth.spotifyBusy,
              accountLabel: auth.spotifyUser ?? '',
              onConnect: () => _connect(context, auth.connectSpotify,
                  'Conectado ao Spotify com sucesso!'),
              onDisconnect: auth.disconnectSpotify,
            ),
            const SizedBox(height: 8),
            LoginStatusCard(
              title: 'YouTube / Google',
              icon: Icons.play_circle_fill,
              color: AppTheme.youtubeRed,
              connected: auth.googleConnected,
              busy: auth.googleBusy,
              accountLabel: auth.googleEmail ?? '',
              onConnect: () => _connect(context, auth.connectGoogle,
                  'Conectado ao Google com sucesso!'),
              onDisconnect: auth.disconnectGoogle,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.playlist_add),
              label: const Text('Selecionar playlists'),
              onPressed: auth.bothConnected
                  ? () => Navigator.pushNamed(context, '/playlists')
                  : null,
            ),
            if (!auth.bothConnected) ...[
              const SizedBox(height: 8),
              Text(
                'Conecte as duas contas para começar.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text('Histórico de transferências'),
              onPressed: () => Navigator.pushNamed(context, '/history'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configurações'),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _connect(
    BuildContext context,
    Future<dynamic> Function() action,
    String successMessage,
  ) async {
    try {
      final result = await action();
      if (!context.mounted) return;
      if (result is bool && !result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login cancelado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao conectar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
