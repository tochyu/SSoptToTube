import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transfer_history_item.dart';
import '../services/history_service.dart';

/// Historico de transferencias realizadas (persistido localmente).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<TransferHistoryItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<TransferHistoryItem>> _load() =>
      context.read<HistoryService>().load();

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: FutureBuilder<List<TransferHistoryItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma transferência realizada ainda.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      item.notFound == 0
                          ? Icons.check_circle
                          : Icons.warning_amber,
                      color:
                          item.notFound == 0 ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      item.playlistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${dateFormat.format(item.date)}\n'
                      '${item.added}/${item.total} adicionadas'
                      '${item.notFound > 0 ? ' • ${item.notFound} não encontradas' : ''}'
                      '${item.skipped > 0 ? ' • ${item.skipped} puladas' : ''}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar histórico?'),
        content:
            const Text('Todos os registros de transferências serão apagados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<HistoryService>().clear();
      _refresh();
    }
  }
}
