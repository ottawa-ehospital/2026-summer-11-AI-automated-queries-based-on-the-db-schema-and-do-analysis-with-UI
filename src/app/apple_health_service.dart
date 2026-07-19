import 'package:health/health.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppleHealthService {
  static final _health = Health();

  static Future<Map<String, dynamic>> getLatestVitals() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 1));

    final types = [
      HealthDataType.HEART_RATE,
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.SLEEP_ASLEEP,
    ];

    bool granted = await _health.requestAuthorization(types);
    if (!granted) throw Exception("Health permission not granted");

    final data = await _health.getHealthDataFromTypes(
      types: types,
      startTime: start,
      endTime: now,
    );

    double heartRate = 0;
    double steps = 0;
    double calories = 0;
    double sleep = 0;

    for (var d in data) {
      final value = (d.value is NumericHealthValue)
          ? (d.value as NumericHealthValue).numericValue
          : (d.value is num ? (d.value as num).toDouble() : 0.0);

      switch (d.type) {
        case HealthDataType.HEART_RATE:
          heartRate += value;
          break;
        case HealthDataType.STEPS:
          steps += value;
          break;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += value;
          break;
        case HealthDataType.SLEEP_ASLEEP:
          sleep += value;
          break;
        default:
          break;
      }
    }

    final vitals = {
      "heart_rate": heartRate.round(),
      "steps": steps.round(),
      "calories": calories.round(),
      "sleep": sleep.round(),
      "timestamp": DateTime.now().toIso8601String(),
      "recorded_on": DateTime.now().toIso8601String(),
    };

    await uploadVitals(vitals);
    return vitals;
  }

  static Future<void> uploadVitals(Map<String, dynamic> vitals) async {
    const api =
        'https://aetab8pjmb.us-east-1.awsapprunner.com/table/wearable_vitals';

    try {
      final prefs = await SharedPreferences.getInstance();
      final patientId = prefs.getInt("patient_id");
      if (patientId == null) {
        print(" Upload skipped: no patient_id (user not logged in)");
        return;
      }
      vitals['patient_id'] = patientId;

      final res = await http.post(
        Uri.parse(api),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(vitals),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print(" Uploaded vitals successfully");
      } else {
        print(" Upload failed: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print(" Upload error: $e");
    }
  }
}
