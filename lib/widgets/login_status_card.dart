import 'package:flutter/material.dart';

/// Cartao de status de conexao de uma conta (Spotify ou Google/YouTube).
class LoginStatusCard extends StatelessWidget {
  const LoginStatusCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.connected,
    required this.busy,
    required this.accountLabel,
    required this.onConnect,
    required this.onDisconnect,
  });

  final String title;
  final IconData icon;
  final Color color;
  final bool connected;
  final bool busy;
  final String accountLabel;
  final Future<void> Function() onConnect;
  final Future<void> Function() onDisconnect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        connected ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: connected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          connected ? accountLabel : 'Desconectado',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            busy
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : connected
                    ? IconButton(
                        tooltip: 'Desconectar',
                        icon: const Icon(Icons.link_off),
                        onPressed: onDisconnect,
                      )
                    : FilledButton.tonal(
                        onPressed: onConnect,
                        child: const Text('Conectar'),
                      ),
          ],
        ),
      ),
    );
  }
}
