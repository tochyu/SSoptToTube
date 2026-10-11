import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/speed_mode.dart';
import '../providers/settings_provider.dart';
import '../providers/transfer_provider.dart';

/// Tela de progresso da transferencia em tempo real, com relatorio final.
class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transfer = context.watch<TransferProvider>();
    final settings = context.watch<SettingsProvider>();

    return PopScope(
      // Impede sair acidentalmente durante a transferencia.
      canPop: !transfer.isRunning,
      child: Scaffold(
        appBar: AppBar(
          title: Text(switch (transfer.status) {
            TransferStatus.running => 'Transferindo...',
            TransferStatus.finished => 'Transferência concluída',
            TransferStatus.cancelled => 'Transferência cancelada',
            TransferStatus.error => 'Erro na transferência',
            _ => 'Preparar transferência',
          }),
        ),
        body: Center(
          child: switch (transfer.status) {
            TransferStatus.idle => _IdleView(
                playlistCount: transfer.selected.length,
                speed: settings.speed,
                skipExisting: settings.skipExisting,
              ),
            TransferStatus.running => _RunningView(transfer: transfer),
            TransferStatus.finished ||
            TransferStatus.cancelled =>
              _ReportView(transfer: transfer),
            TransferStatus.error => _ErrorView(transfer: transfer),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado inicial: resumo e botao iniciar
// ---------------------------------------------------------------------------
class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.playlistCount,
    required this.speed,
    required this.skipExisting,
  });

  final int playlistCount;
  final SpeedMode speed;
  final bool skipExisting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.library_music,
              size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            '$playlistCount playlist(s) selecionada(s)',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Velocidade: ${speed.label}\n'
            '${skipExisting ? 'Músicas que já existirem na playlist serão puladas.' : ''}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar transferência'),
            onPressed: () =>
                context.read<TransferProvider>().run(),
          ),
          const SizedBox(height: 8),
          Text(
            'Você pode acompanhar o progresso em tempo real.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progresso em tempo real
// ---------------------------------------------------------------------------
class _RunningView extends StatelessWidget {
  const _RunningView({required this.transfer});

  final TransferProvider transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Playlist ${transfer.playlistIndex + 1} de ${transfer.totalPlaylists}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            transfer.currentPlaylistName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: transfer.overallProgress),
          const SizedBox(height: 8),
          Text(
            transfer.totalTracksCurrent > 0
                ? '${transfer.trackIndex}/${transfer.totalTracksCurrent} músicas nesta playlist'
                : 'Carregando músicas...',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountChip(
                label: 'Adicionadas',
                value: transfer.added,
                color: Colors.green,
              ),
              _CountChip(
                label: 'Não encontradas',
                value: transfer.notFound,
                color: Colors.orange,
              ),
              _CountChip(
                label: 'Puladas',
                value: transfer.skipped,
                color: Colors.blueGrey,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Buscando: ${transfer.currentTrack.isEmpty ? '…' : transfer.currentTrack}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 32),
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar transferência'),
            onPressed: () => transfer.requestCancel(),
          ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Relatorio final
// ---------------------------------------------------------------------------
class _ReportView extends StatelessWidget {
  const _ReportView({required this.transfer});

  final TransferProvider transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          transfer.status == TransferStatus.finished
              ? Icons.check_circle
              : Icons.info_outline,
          size: 72,
          color: transfer.status == TransferStatus.finished
              ? Colors.green
              : Colors.orange,
        ),
        const SizedBox(height: 12),
        Text(
          transfer.status == TransferStatus.finished
              ? 'Transferência concluída!'
              : 'Transferência interrompida',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${transfer.added} adicionadas • '
          '${transfer.notFound} não encontradas • '
          '${transfer.skipped} já existiam (puladas)',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        ...transfer.sessionReports.map(
          (r) => Card(
            child: ListTile(
              leading: Icon(
                r.notFound == 0 ? Icons.check_circle : Icons.warning_amber,
                color: r.notFound == 0 ? Colors.green : Colors.orange,
              ),
              title: Text(r.playlistName,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text('${r.added}/${r.total} músicas adicionadas'),
            ),
          ),
        ),
        if (transfer.notFoundTracks.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Músicas não encontradas no YouTube:',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          ...transfer.notFoundTracks.map(
            (t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• $t', style: theme.textTheme.bodySmall),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () {
            context.read<TransferProvider>().reset();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text('Concluir'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Erro
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.transfer});

  final TransferProvider transfer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 72, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'A transferência falhou',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            transfer.error ?? 'Erro desconhecido.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              context.read<TransferProvider>().reset();
              Navigator.pop(context);
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}
