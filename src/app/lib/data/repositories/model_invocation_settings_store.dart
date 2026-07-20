import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/model_invocation_settings.dart';

class ModelInvocationSettingsStore {
  static const _prefsKey = 'model_invocation_settings';

  Future<ModelInvocationSettings?> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return ModelInvocationSettings.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<ModelInvocationSettings> loadEffective() async {
    return await loadSaved() ?? ModelInvocationSettings.defaults();
  }

  Future<void> save(ModelInvocationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(settings.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
