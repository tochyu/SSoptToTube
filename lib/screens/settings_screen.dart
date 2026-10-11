import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/speed_mode.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

/// Configuracoes: tema, velocidade, opcoes de transferencia e logout.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------------------------------------------------------
          // Aparencia
          // ---------------------------------------------------------------
          Text('Aparência', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Escuro (padrão)'),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.mode,
                  onChanged: (m) =>
                      m != null ? themeProvider.setMode(m) : null,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Claro'),
                  value: ThemeMode.light,
                  groupValue: themeProvider.mode,
                  onChanged: (m) =>
                      m != null ? themeProvider.setMode(m) : null,
                ),
                RadioListTile<ThemeMode>(
                  title: const Text('Seguir o sistema'),
                  value: ThemeMode.system,
                  groupValue: themeProvider.mode,
                  onChanged: (m) =>
                      m != null ? themeProvider.setMode(m) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ---------------------------------------------------------------
          // Velocidade
          // ---------------------------------------------------------------
          Text('Velocidade da transferência',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: SpeedMode.values
                  .map(
                    (mode) => RadioListTile<SpeedMode>(
                      title: Text(mode.label),
                      subtitle: Text(
                        mode.description,
                        style: theme.textTheme.bodySmall,
                      ),
                      value: mode,
                      groupValue: settings.speed,
                      onChanged: (m) =>
                          m != null ? settings.setSpeed(m) : null,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------------------------------------------------------
          // Opcoes de transferencia
          // ---------------------------------------------------------------
          Text('Transferência', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Pular músicas que já existem'),
              subtitle: const Text(
                'Se a playlist já existir no YouTube, apenas as músicas '
                'que faltam serão adicionadas.',
              ),
              value: settings.skipExisting,
              onChanged: (v) => settings.setSkipExisting(v),
            ),
          ),
          const SizedBox(height: 24),

          // ---------------------------------------------------------------
          // Contas
          // ---------------------------------------------------------------
          Text('Contas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.graphic_eq,
                      color: AppTheme.spotifyGreen),
                  title: const Text('Spotify'),
                  subtitle: Text(auth.spotifyUser ?? 'Desconectado'),
                  trailing: auth.spotifyConnected
                      ? TextButton(
                          onPressed: () =>
                              _confirmLogout(context, 'Spotify',
                                  auth.disconnectSpotify),
                          child: const Text('Sair'),
                        )
                      : null,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.play_circle_fill,
                      color: AppTheme.youtubeRed),
                  title: const Text('Google / YouTube'),
                  subtitle: Text(auth.googleEmail ?? 'Desconectado'),
                  trailing: auth.googleConnected
                      ? TextButton(
                          onPressed: () => _confirmLogout(
                              context, 'Google', auth.disconnectGoogle),
                          child: const Text('Sair'),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${AppConstants.appName} v${AppConstants.appVersion}\n'
            'Este app usa apenas APIs oficiais. Nenhuma música é baixada.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(
    BuildContext context,
    String account,
    Future<void> Function() logout,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sair do $account?'),
        content: Text('Você precisará conectar novamente para transferir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed == true) await logout();
  }
}
