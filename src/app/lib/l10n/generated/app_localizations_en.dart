// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Health App';

  @override
  String get brandName => 'Smart Health';

  @override
  String get loginHeaderSubtitle => 'Your personal health dashboard';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Enter your eHospital credentials to continue';

  @override
  String get emailAddressHint => 'Email address';

  @override
  String get passwordHint => 'Password';

  @override
  String get signInButton => 'Sign In';

  @override
  String get emailRequiredError => 'Please enter your email';

  @override
  String get emailNotFoundError => 'Email not found. Please try again.';

  @override
  String get passwordRequiredError => 'Please enter your password';

  @override
  String get invalidCredentialsError =>
      'Invalid email or password. Please try again.';

  @override
  String get unsupportedIdentityError =>
      'This identity signed in successfully, but patient features require a Patient login.';

  @override
  String get privacyNoticeTitle => 'Privacy Notice';

  @override
  String get privacyNoticeBody =>
      'This app uses a local Llama model through Ollama to process your health data. By continuing, you agree that your data may be sent to the local Ollama service running on this device for processing. Please review our Privacy Policy for more details.';

  @override
  String get privacyAgreeButton => 'I Agree';

  @override
  String get medicalDisclaimerTitle => 'Medical Disclaimer';

  @override
  String get medicalDisclaimerBody =>
      'IMPORTANT: This app is for informational and wellness purposes only. It is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment recommendations.\n\nAll wellness indicators, risk scores, and health data displayed are for general awareness only and must not be used to make medical decisions. This app has not been approved by the FDA or any regulatory authority as a medical device.\n\nAlways consult a qualified, licensed healthcare professional for any health concerns or before making any health-related decisions.';

  @override
  String get medicalDisclaimerConfirmButton => 'I Understand';

  @override
  String get patientDashboardTitle => 'Patient Dashboard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get logoutTitle => 'Logout';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get closeButton => 'Close';

  @override
  String get notificationsEnabledMessage =>
      'Daily reminders enabled at 9:00 AM';

  @override
  String get notificationsDisabledMessage => 'Notifications disabled';

  @override
  String get logoutConfirmBody => 'Are you sure you want to logout?';

  @override
  String get accountSection => 'Account';

  @override
  String get profileTitle => 'Profile';

  @override
  String get notificationsSection => 'Notifications';

  @override
  String get dailyHealthRemindersTitle => 'Daily Health Reminders';

  @override
  String get dailyHealthRemindersSubtitle => '9:00 AM reminder to check vitals';

  @override
  String get emergencySection => 'Emergency';

  @override
  String get emergencySosCardTitle => 'Emergency SOS Card';

  @override
  String get emergencySosCardSubtitle => 'Blood type, allergies, contact';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersionTitle => 'App Version';

  @override
  String get appVersionValue => '1.0.0';

  @override
  String get smartHealthAppSubtitle => 'AI-powered patient monitoring';

  @override
  String get dataSourcesTitle => 'Data Sources';

  @override
  String get clinicalWearableDataTitle => 'Clinical & Wearable Data';

  @override
  String get clinicalWearableDataSubtitle =>
      'eHospital patient database (institutional)';

  @override
  String get aiHealthResponsesTitle => 'AI Health Responses';

  @override
  String get aiHealthResponsesSubtitle => 'Configured AI provider';

  @override
  String get vitalsReferenceRangesTitle => 'Vitals Reference Ranges';

  @override
  String get vitalsReferenceRangesSubtitle =>
      'American Heart Association (AHA) guidelines';

  @override
  String get dangerZoneSection => 'Danger Zone';

  @override
  String get logoutSubtitle => 'Clear all data and return to login';

  @override
  String get sourceClinicalTitle => 'Clinical Records & Risk Scores';

  @override
  String get sourceClinicalDescription =>
      'Sourced from the eHospital institutional patient database. Includes ECG results, diabetes analysis, heart disease risk, stroke prediction, lab tests, and diagnosis records provided by the connected hospital system.';

  @override
  String get sourceWearableTitle => 'Wearable Vitals';

  @override
  String get sourceWearableDescription =>
      'Heart rate, steps, calories, and sleep data sourced from Apple HealthKit via Apple Watch or other connected health devices.';

  @override
  String get sourceAssistantTitle => 'AI Health Assistant';

  @override
  String get sourceAssistantDescription =>
      'Responses generated by a local Llama model through Ollama. For informational purposes only - not a substitute for professional medical advice.';

  @override
  String get sourceVitalsTitle => 'Vitals Reference Ranges';

  @override
  String get sourceVitalsDescription =>
      'Normal ranges for blood pressure, heart rate, and SpO2 are based on guidelines from the American Heart Association (AHA) and World Health Organization (WHO).';

  @override
  String get sourceBmiTitle => 'BMI Classification';

  @override
  String get sourceBmiDescription =>
      'Body Mass Index categories (Underweight, Normal, Overweight, Obese) follow the WHO BMI classification standard.';

  @override
  String get medicalAdviceShortDisclaimer =>
      'This app is for informational purposes only and does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.';

  @override
  String get profileScreenTitle => 'My Profile';

  @override
  String get profileNotLoggedIn => 'Not logged in';

  @override
  String get profileInvalidPatientId => 'Invalid patient ID';

  @override
  String profileNetworkError(String error) {
    return 'Network error: $error';
  }

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get patientIdLabel => 'Patient ID';

  @override
  String get usernameLabel => 'Username';

  @override
  String get emailLabel => 'Email';

  @override
  String get roleLabel => 'Role';

  @override
  String get statusLabel => 'Status';

  @override
  String get memberSinceLabel => 'Member Since';

  @override
  String get bmiCalculatorTitle => 'BMI Calculator';

  @override
  String get validHeightWeightError => 'Please enter valid height and weight';

  @override
  String get heightCmLabel => 'Height (cm)';

  @override
  String get weightKgLabel => 'Weight (kg)';

  @override
  String get calculateBmiButton => 'Calculate BMI';

  @override
  String get bmiReferenceTitle => 'BMI Reference';

  @override
  String get bmiUnderweight => 'Underweight';

  @override
  String get bmiNormal => 'Normal';

  @override
  String get bmiOverweight => 'Overweight';

  @override
  String get bmiObese => 'Obese';

  @override
  String get medicationsTitle => 'Medications';

  @override
  String get addMedicationTitle => 'Add Medication';

  @override
  String get medicationNameLabel => 'Medication Name';

  @override
  String get dosageLabel => 'Dosage (e.g. 10mg)';

  @override
  String get frequencyLabel => 'Frequency (e.g. Once daily)';

  @override
  String get timeLabel => 'Time (e.g. 8:00 AM)';

  @override
  String get noMedicationsYet => 'No medications yet';

  @override
  String get tapAddMedication => 'Tap + to add one';

  @override
  String medicationSummary(String dosage, String frequency, String time) {
    return '$dosage | $frequency | $time';
  }

  @override
  String get symptomLogTitle => 'Symptom Log';

  @override
  String get logSymptomTitle => 'Log Symptom';

  @override
  String get symptomNameLabel => 'Symptom Name';

  @override
  String get severityLabel => 'Severity';

  @override
  String get notesOptionalLabel => 'Notes (optional)';

  @override
  String get noSymptomsLogged => 'No symptoms logged';

  @override
  String get tapLogSymptom => 'Tap + to log one';

  @override
  String get severityVeryMild => 'Very Mild';

  @override
  String get severityMild => 'Mild';

  @override
  String get severityModerate => 'Moderate';

  @override
  String get severitySevere => 'Severe';

  @override
  String get severityVerySevere => 'Very Severe';

  @override
  String severityValueLabel(int severity, String label) {
    return '$severity | $label';
  }

  @override
  String severityBadgeLabel(String label, int severity) {
    return '$label ($severity/5)';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get tapToSet => 'Tap to set';

  @override
  String get healthGoalsTitle => 'Health Goals';

  @override
  String get dailyStepsTitle => 'Daily Steps';

  @override
  String get sleepTitle => 'Sleep';

  @override
  String get caloriesBurnedTitle => 'Calories Burned';

  @override
  String get stepsGoalTitle => 'Steps';

  @override
  String get caloriesGoalTitle => 'Calories';

  @override
  String get stepsUnit => 'steps';

  @override
  String get hoursUnit => 'hours';

  @override
  String get hrsUnit => 'hrs';

  @override
  String get kcalUnit => 'kcal';

  @override
  String get healthGoalsGoalsTab => 'Goals';

  @override
  String get healthGoalsTrainingRecordsTab => 'Training Records';

  @override
  String get trainingRecordsTitle => 'Training Records';

  @override
  String get trainingRecordsRefreshTooltip => 'Refresh training records';

  @override
  String get trainingRecordsSyncTooltip => 'Sync platform workouts';

  @override
  String get trainingRecordsLoading => 'Loading training records...';

  @override
  String get trainingRecordsEmpty => 'No synced training records available.';

  @override
  String get trainingRecordsError => 'Could not load training records.';

  @override
  String get trainingRecordsSourceLabel => 'Source';

  @override
  String get trainingRecordsDurationLabel => 'Duration';

  @override
  String get trainingRecordsDistanceLabel => 'Distance';

  @override
  String get trainingRecordsEnergyLabel => 'Energy';

  @override
  String get trainingRecordsStepsLabel => 'Steps';

  @override
  String get trainingRecordsUnknownDate => 'Unknown date';

  @override
  String get trainingRecordsSyncSuccess => 'Workout sync complete.';

  @override
  String get editGoalTooltip => 'Edit goal';

  @override
  String editGoalTitle(String title) {
    return 'Edit $title Goal';
  }

  @override
  String metricValueInt(int value, String unit) {
    return '$value $unit';
  }

  @override
  String metricValueDecimal(double value, String unit) {
    final intl.NumberFormat valueNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String valueString = valueNumberFormat.format(value);

    return '$valueString $unit';
  }

  @override
  String goalProgressValue(String actual, String goal, String unit) {
    return '$actual / $goal $unit';
  }

  @override
  String get emergencySosTitle => 'Emergency SOS';

  @override
  String get emergencyUpdateWarning =>
      'Keep this information up to date. It could save your life in an emergency.';

  @override
  String get medicalInformationTitle => 'Medical Information';

  @override
  String get emergencyContactTitle => 'Emergency Contact';

  @override
  String get bloodTypeLabel => 'Blood Type';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get contactNameLabel => 'Contact Name';

  @override
  String get contactPhoneLabel => 'Contact Phone';

  @override
  String editFieldTitle(String title) {
    return 'Edit $title';
  }

  @override
  String get callEmergencyButton => 'CALL EMERGENCY (911)';

  @override
  String get cannotLaunchPhoneDialer => 'Cannot launch phone dialer';

  @override
  String dashboardHelloUser(String username) {
    return 'Hello, $username!';
  }

  @override
  String get dashboardWelcome => 'Welcome!';

  @override
  String get dashboardPrompt => 'What would you like to check today?';

  @override
  String get healthMonitoringSection => 'Health Monitoring';

  @override
  String get healthManagementSection => 'Health Management';

  @override
  String get wearableVitalsTitle => 'Wearable Vitals';

  @override
  String get wearableVitalsSubtitle => 'Steps | Calories | HR';

  @override
  String get vitalsHistoryTitle => 'Vitals History';

  @override
  String get vitalsHistorySubtitle => 'Clinical records';

  @override
  String get healthInsightsTitle => 'Health Insights';

  @override
  String get healthInsightsSubtitle => 'Risk analysis & alerts';

  @override
  String get trendAnalysisTitle => 'Trend Analysis';

  @override
  String get trendAnalysisSubtitle => 'This week vs last';

  @override
  String get medicationsSubtitle => 'Track & manage meds';

  @override
  String get symptomLogSubtitle => 'Daily symptom diary';

  @override
  String get healthGoalsSubtitle => 'Steps | Sleep | Calories';

  @override
  String get bmiCalculatorSubtitle => 'Check your BMI';

  @override
  String get aiHealthAssistantTitle => 'AI Health Assistant';

  @override
  String get aiHealthAssistantSubtitle => 'Ask AI about your health data';

  @override
  String get assistantPickerTitle => 'Choose an AI tool';

  @override
  String assistantPickerOpenAction(String moduleName) {
    return 'Open $moduleName';
  }

  @override
  String get assistantModuleChatLabel => 'Chat';

  @override
  String get assistantModuleChatDescription =>
      'Ask questions about your health data and wellness trends.';

  @override
  String get assistantModuleReportLabel => 'Report Analyze';

  @override
  String get assistantModuleReportDescription =>
      'Upload lab work, reports, images, or PDFs for plain-language analysis.';

  @override
  String get assistantModuleNutritionLabel => 'Nutrition Monitor';

  @override
  String get assistantModuleNutritionDescription =>
      'Analyze meal images, check EHR-aware nutrition risks, and track goals.';

  @override
  String get clearChatTooltip => 'Clear chat';

  @override
  String get newChatTooltip => 'New chat';

  @override
  String get assistantHistoryTooltip => 'Chat history';

  @override
  String get assistantNoHistory => 'No saved chats yet';

  @override
  String get aiWellnessAssistantTitle => 'AI Wellness Assistant';

  @override
  String get aiWellnessAssistantDisclaimer =>
      'General wellness info only | Not medical advice';

  @override
  String get assistantEmptyTitle => 'Ask about your wellness data';

  @override
  String get assistantPromptHeartRate =>
      '\"What does my heart rate trend mean?\"';

  @override
  String get assistantPromptActivity =>
      '\"How can I improve my activity levels?\"';

  @override
  String get assistantGeneralDisclaimer =>
      'For general wellness info only.\nNot a substitute for medical advice.';

  @override
  String get assistantInputHint => 'Ask about your health...';

  @override
  String get assistantLoginRequired =>
      'Please log in before using the health assistant.';

  @override
  String assistantErrorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get assistantThinking => 'Thinking...';

  @override
  String get deviceManagerTitle => 'Device Manager';

  @override
  String get deviceInfoTitle => 'Apple Watch -> eHospital';

  @override
  String get deviceInfoBody =>
      'On a real device: patient logs in and taps \"Sync Apple Watch\" to push live Health data.\nFor demo/testing: tap Simulate to generate 7 days of realistic wearable data for any patient.';

  @override
  String patientsInDb(int count) {
    return '$count Patients in eHospital DB';
  }

  @override
  String patientFallbackName(String id) {
    return 'Patient $id';
  }

  @override
  String get connectedStatus => 'CONNECTED';

  @override
  String get noDataStatus => 'NO DATA';

  @override
  String patientDeviceMeta(String patientId, String email) {
    return 'ID: $patientId  |  $email';
  }

  @override
  String get neverSynced => 'Never synced';

  @override
  String recordsCount(int count) {
    return '$count records';
  }

  @override
  String get simulateButton => 'Simulate';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get simulatingDataTitle => 'Simulating Data';

  @override
  String patientNameLabel(String name) {
    return 'Patient: $name';
  }

  @override
  String get appleHealthPipeline =>
      'Apple Watch  -> Apple Health  -> eHospital DB';

  @override
  String uploadCompleteMessage(int total) {
    return '$total days uploaded to eHospital.';
  }

  @override
  String uploadingDayMessage(int progress, int total) {
    return 'Uploading day $progress of $total...';
  }

  @override
  String get lastWeekLabel => 'Last Week';

  @override
  String get thisWeekLabel => 'This Week';

  @override
  String get trendDisclaimer =>
      'For informational purposes only. Not a medical device. Always consult a qualified healthcare professional before making any medical decisions.';

  @override
  String get stepsTitle => 'Steps';

  @override
  String get stepsTrendDescription =>
      'Average daily steps this week vs last week. Goal: 10,000 steps/day.';

  @override
  String get activeCaloriesTitle => 'Active Calories';

  @override
  String get activeCaloriesTrendDescription =>
      'Average calories burned per day. Healthy range: 300-600 kcal/day.';

  @override
  String get heartRateTitle => 'Heart Rate';

  @override
  String get heartRateTrendDescription =>
      'Average resting heart rate. Normal range: 60-100 bpm.';

  @override
  String get sleepTrendDescription =>
      'Average hours of sleep per night. Recommended: 7-9 hrs/night.';

  @override
  String get bpmUnit => 'bpm';

  @override
  String get noDataThisWeek => 'No data this week';

  @override
  String get belowNormalRange => 'Below normal range';

  @override
  String get aboveNormalRange => 'Above normal range';

  @override
  String get withinNormalRange => 'Within normal range';

  @override
  String trendChartAxisLabel(String period, String value, String unit) {
    return '$period\n$value $unit';
  }

  @override
  String get aiInsightLabel => 'AI Insight';

  @override
  String get generatingInsight => 'Generating...';

  @override
  String get syncDataToGenerateInsight => 'Sync data to generate insight.';

  @override
  String get clinicalVitalsHistoryTitle => 'Clinical Vitals History';

  @override
  String recordsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'records',
      one: 'record',
    );
    return '$count $_temp0 found';
  }

  @override
  String get noVitalsHistoryFound => 'No vitals history found';

  @override
  String get relatedRecordsTitle => 'Related Records';

  @override
  String get historyDisclaimer =>
      'For informational & wellness purposes only. Not a medical device. Does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String moreRecords(int count) {
    return '+ $count more records';
  }

  @override
  String get labTestsTitle => 'Lab Tests';

  @override
  String get ecgTitle => 'ECG';

  @override
  String get glucoseWellnessTitle => 'Glucose Wellness';

  @override
  String get heartHealthIndicatorsTitle => 'Heart Health Indicators';

  @override
  String get strokeRiskIndicatorsTitle => 'Stroke Risk Indicators';

  @override
  String get clinicalRecordsTitle => 'Clinical Records';

  @override
  String get vitalSignsTitle => 'Vital Signs';

  @override
  String get syncingAppleWatch => 'Syncing from Apple Watch...';

  @override
  String get vitalsSyncIssue =>
      'Data sync issue: Heart rate recorded as 0 BPM. Wearable may not be syncing correctly.';

  @override
  String get deviceManagerTooltip => 'Device Manager';

  @override
  String get syncFromAppleWatchTooltip => 'Sync from Apple Watch';

  @override
  String get logVitalsManuallyTooltip => 'Log Vitals manually';

  @override
  String get syncingShort => 'Syncing...';

  @override
  String get syncAppleWatchButton => 'Sync Apple Watch';

  @override
  String get logVitalsTitle => 'Log Vitals to eHospital';

  @override
  String get wearableVitalsEndpointLabel => 'POST -> /table/wearable_vitals';

  @override
  String get heartRateBpmLabel => 'Heart Rate (bpm)';

  @override
  String get stepsInputLabel => 'Steps';

  @override
  String get caloriesInputLabel => 'Calories';

  @override
  String get sleepHoursInputLabel => 'Sleep (hrs)';

  @override
  String get sendingButton => 'Sending...';

  @override
  String get sendToEHospitalButton => 'Send to eHospital';

  @override
  String get enterAtLeastOneValue => 'Enter at least one value';

  @override
  String get vitalsSavedMessage => 'Vitals saved to eHospital DB';

  @override
  String get clinicalReferenceTitle => 'Clinical Reference';

  @override
  String get eHospitalSourceLabel => 'eHospital';

  @override
  String get ecgShortLabel => 'ECG';

  @override
  String get bloodPressureLabel => 'Blood Pressure';

  @override
  String get normalRangeLabel => 'Normal range';

  @override
  String get latestMetricLabel => 'Latest';

  @override
  String get averageMetricLabel => 'Average';

  @override
  String get minMetricLabel => 'Min';

  @override
  String get maxMetricLabel => 'Max';

  @override
  String get noDataStatusLabel => 'No Data';

  @override
  String get lowStatusLabel => 'Low';

  @override
  String get highStatusLabel => 'High';

  @override
  String get normalStatusLabel => 'Normal';

  @override
  String get stepsMetricDescription =>
      'Steps walked today. A healthy goal is 10,000 steps per day.';

  @override
  String get caloriesMetricDescription =>
      'Active calories burned. Healthy range: 300-800 kcal/day.';

  @override
  String get heartRateMetricDescription =>
      'Heart rate in beats per minute. Normal resting: 60-100 bpm.';

  @override
  String get sleepMetricDescription =>
      'Hours of sleep recorded. Recommended: 7-9 hours per night.';

  @override
  String get clinicalBaselineNote =>
      'Green dashed line = clinical baseline HR from hospital records.';

  @override
  String get wearableSleepMissingNote =>
      '0 hrs means the wearable did not record sleep for that period.';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get unifiedHealthAnalysisTitle => 'Unified Health Analysis';

  @override
  String get unifiedHealthAnalysisSubtitle =>
      'Wearable + clinical data - timestamp merged';

  @override
  String mergedRecordPairs(int count) {
    return '$count wearable-clinical record pairs merged (+/-48h window)';
  }

  @override
  String insightsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Insights',
      one: 'Insight',
    );
    return '$count $_temp0 Found';
  }

  @override
  String get insightsMedicalFooter =>
      'IMPORTANT: This app is for informational and wellness purposes only. It is not a medical device and does not provide medical advice, diagnosis, or treatment. All wellness indicators and risk scores are for general awareness only. Always consult a qualified healthcare professional before making any health-related decisions.';

  @override
  String get insightsDisclaimer =>
      'For informational & wellness purposes only. Not a medical device. Does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.';

  @override
  String get clinicalSummaryTitle => 'Patient Clinical Summary';

  @override
  String get clinicalVitalsMostRecent => 'Clinical Vitals (Most Recent)';

  @override
  String get wearableActivityMostRecent => 'Wearable Activity (Most Recent)';

  @override
  String noteLabel(String note) {
    return 'Note: $note';
  }
}
