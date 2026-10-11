/// Registro de uma playlist transferida, usado no relatorio final
/// e no historico persistente de transferencias.
class TransferHistoryItem {
  final String playlistName;
  final int total;
  final int added;
  final int notFound;
  final int skipped;
  final DateTime date;

  const TransferHistoryItem({
    required this.playlistName,
    required this.total,
    required this.added,
    required this.notFound,
    required this.skipped,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'playlistName': playlistName,
        'total': total,
        'added': added,
        'notFound': notFound,
        'skipped': skipped,
        'date': date.toIso8601String(),
      };

  factory TransferHistoryItem.fromJson(Map<String, dynamic> json) {
    return TransferHistoryItem(
      playlistName: json['playlistName']?.toString() ?? 'Sem nome',
      total: (json['total'] as num?)?.toInt() ?? 0,
      added: (json['added'] as num?)?.toInt() ?? 0,
      notFound: (json['notFound'] as num?)?.toInt() ?? 0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
