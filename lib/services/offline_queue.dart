import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight persistent queue for expense entries created while offline.
/// Firestore still provides its own offline persistence for normal writes;
/// this queue makes PennyPal's offline requirement explicit and testable,
/// including a visible pending-sync state for entries made with no network.
class OfflineQueue {
  static const _key = 'pennypal_pending_transactions_v2';
  static SharedPreferences? _prefs;
  static Future<void> _writeChain = Future<void>.value();

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<List<Map<String, dynamic>>> pendingTransactions() async {
    await init();
    final raw = _prefs!.getStringList(_key) ?? const <String>[];
    return raw.map((item) {
      try {
        return Map<String, dynamic>.from(jsonDecode(item) as Map);
      } catch (_) {
        return <String, dynamic>{};
      }
    }).where((item) => item.isNotEmpty).toList();
  }

  static Future<void> queueTransaction(Map<String, dynamic> data) {
    _writeChain = _writeChain.then((_) async {
      await init();
      final current = await pendingTransactions();
      current.add(Map<String, dynamic>.from(data));
      await _save(current);
    });
    return _writeChain;
  }

  static Future<void> replacePending(List<Map<String, dynamic>> items) {
    _writeChain = _writeChain.then((_) async {
      await init();
      await _save(items);
    });
    return _writeChain;
  }

  static Future<int> pendingCount() async => (await pendingTransactions()).length;

  static Future<void> clear() async {
    await init();
    await _prefs!.remove(_key);
  }

  static Future<void> _save(List<Map<String, dynamic>> items) async {
    await _prefs!.setStringList(
      _key,
      items.map((item) => jsonEncode(item)).toList(),
    );
  }

  // Kept for backwards-compatible call sites.
  static Future<void> queue(Map<String, dynamic> data) => queueTransaction(data);

  static Future<int> sync() async => 0;
}
