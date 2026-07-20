import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/health_alert_models.dart';

class AlertDecisionStore {
  String _key(String patientId) => 'alert_decisions_$patientId';

  Future<List<AlertDecisionRecord>> load(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(patientId)) ?? '[]';
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    final records = decoded
        .whereType<Map>()
        .map(
          (item) =>
              AlertDecisionRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    records.sort((a, b) => b.storedAt.compareTo(a.storedAt));
    return records;
  }

  Future<void> append(String patientId, AlertDecisionRecord record) async {
    final records = await load(patientId);
    records.insert(0, record);
    await save(patientId, records.take(100).toList());
  }

  Future<void> save(String patientId, List<AlertDecisionRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(patientId),
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }

  Future<void> clear(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(patientId));
  }
}
