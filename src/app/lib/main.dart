import 'package:flutter/material.dart';
import 'package:smart_health_app/features/auth/auth.dart';
import 'package:smart_health_app/features/dashboard/dashboard.dart';
import 'package:smart_health_app/features/devices/devices.dart';
import 'package:smart_health_app/features/emergency/emergency.dart';
import 'package:smart_health_app/features/goals/goals.dart';
import 'package:smart_health_app/features/health_assistant/health_assistant.dart';
import 'package:smart_health_app/features/insights/insights.dart';
import 'package:smart_health_app/features/medications/medications.dart';
import 'package:smart_health_app/features/profile/profile.dart';
import 'package:smart_health_app/features/settings/settings.dart';
import 'package:smart_health_app/features/symptoms/symptoms.dart';
import 'package:smart_health_app/features/tools/tools.dart';
import 'package:smart_health_app/features/trends/trends.dart';
import 'package:smart_health_app/features/urgent_care/urgent_care.dart';
import 'package:smart_health_app/features/vitals/vitals.dart';
import 'package:smart_health_app/l10n/generated/app_localizations.dart';
import 'package:smart_health_app/services/health_alert_coordinator.dart';
import 'package:smart_health_app/ui/app_theme.dart';

void main() {
  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) =>
          HealthAlertCoordinator(child: child ?? const SizedBox.shrink()),
      routes: {
        "/": (_) => const LoginScreen(),
        "/dashboard": (_) => const PatientDashboard(),
        "/vitals": (_) => const VitalsScreen(),
        "/history": (_) => const VitalsHistoryScreen(),
        "/insights": (_) => const HealthInsightsScreen(),
        "/assistant": (_) => const HealthAssistantScreen(),
        "/profile": (_) => const ProfileScreen(),
        "/medications": (_) => const MedicationTrackerScreen(),
        "/symptoms": (_) => const SymptomLoggerScreen(),
        "/goals": (_) => const HealthGoalsScreen(),
        "/bmi": (_) => const BmiCalculatorScreen(),
        "/trends": (_) => const TrendComparisonScreen(),
        "/emergency": (_) => const EmergencySosScreen(),
        "/urgent-care": (_) => const UrgentCareScreen(),
        "/settings": (_) => const SettingsScreen(),
        "/settings/alert-decisions": (_) => const AlertDecisionHistoryScreen(),
        "/settings/model-invocation": (_) =>
            const ModelInvocationSettingsScreen(),
        "/devices": (_) => const DeviceConnectionScreen(),
      },
      initialRoute: "/",
    );
  }
}
