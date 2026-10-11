import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/transfer_history_item.dart';

/// Historico persistente de transferencias (armazenado localmente
/// via shared_preferences como lista JSON).
class HistoryService {
  static const _key = 'transfer_history';

  Future<List<TransferHistoryItem>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TransferHistoryItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Adiciona novos registros ao historico (os mais recentes por ultimo).
  Future<void> addAll(List<TransferHistoryItem> items) async {
    if (items.isEmpty) return;
    final all = [...await load(), ...items];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
