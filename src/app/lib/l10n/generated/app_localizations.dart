import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application title used by MaterialApp.
  ///
  /// In en, this message translates to:
  /// **'Smart Health App'**
  String get appTitle;

  /// Primary product name displayed in the login header.
  ///
  /// In en, this message translates to:
  /// **'Smart Health'**
  String get brandName;

  /// Subtitle displayed below the product name on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Your personal health dashboard'**
  String get loginHeaderSubtitle;

  /// Login form title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Login form helper text.
  ///
  /// In en, this message translates to:
  /// **'Enter your eHospital credentials to continue'**
  String get signInSubtitle;

  /// Email input hint on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddressHint;

  /// Password input hint on the login screen.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// Primary login button label.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// Validation error when the login email field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get emailRequiredError;

  /// Login error when the backend cannot find the email.
  ///
  /// In en, this message translates to:
  /// **'Email not found. Please try again.'**
  String get emailNotFoundError;

  /// Validation error when the login password field is empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get passwordRequiredError;

  /// Login error when eHospital credentials are rejected.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password. Please try again.'**
  String get invalidCredentialsError;

  /// Login error when a non-patient identity signs in but the app requires patient context.
  ///
  /// In en, this message translates to:
  /// **'This identity signed in successfully, but patient features require a Patient login.'**
  String get unsupportedIdentityError;

  /// Title of the local AI privacy notice dialog.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get privacyNoticeTitle;

  /// Body copy of the local AI privacy notice dialog.
  ///
  /// In en, this message translates to:
  /// **'This app uses a local Llama model through Ollama to process your health data. By continuing, you agree that your data may be sent to the local Ollama service running on this device for processing. Please review our Privacy Policy for more details.'**
  String get privacyNoticeBody;

  /// Privacy notice confirmation button.
  ///
  /// In en, this message translates to:
  /// **'I Agree'**
  String get privacyAgreeButton;

  /// Title of the medical disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'Medical Disclaimer'**
  String get medicalDisclaimerTitle;

  /// Body copy of the medical disclaimer dialog.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: This app is for informational and wellness purposes only. It is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment recommendations.\n\nAll wellness indicators, risk scores, and health data displayed are for general awareness only and must not be used to make medical decisions. This app has not been approved by the FDA or any regulatory authority as a medical device.\n\nAlways consult a qualified, licensed healthcare professional for any health concerns or before making any health-related decisions.'**
  String get medicalDisclaimerBody;

  /// Medical disclaimer confirmation button.
  ///
  /// In en, this message translates to:
  /// **'I Understand'**
  String get medicalDisclaimerConfirmButton;

  /// Dashboard screen title.
  ///
  /// In en, this message translates to:
  /// **'Patient Dashboard'**
  String get patientDashboardTitle;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Logout action title.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutTitle;

  /// Generic cancel button label.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Generic close button label.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// Snackbar shown after enabling daily health reminders.
  ///
  /// In en, this message translates to:
  /// **'Daily reminders enabled at 9:00 AM'**
  String get notificationsEnabledMessage;

  /// Snackbar shown after disabling notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabledMessage;

  /// Logout confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmBody;

  /// Settings section label for account settings.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// Profile settings tile title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Settings section label for notification settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// Settings tile title for daily reminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Health Reminders'**
  String get dailyHealthRemindersTitle;

  /// Settings tile subtitle for daily reminders.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM reminder to check vitals'**
  String get dailyHealthRemindersSubtitle;

  /// Settings section label for emergency settings.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergencySection;

  /// Settings tile title for emergency card.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS Card'**
  String get emergencySosCardTitle;

  /// Settings tile subtitle for emergency card.
  ///
  /// In en, this message translates to:
  /// **'Blood type, allergies, contact'**
  String get emergencySosCardSubtitle;

  /// Settings section label for about information.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// Settings tile title for app version.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersionTitle;

  /// Displayed app version.
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get appVersionValue;

  /// Settings subtitle for the app info tile.
  ///
  /// In en, this message translates to:
  /// **'AI-powered patient monitoring'**
  String get smartHealthAppSubtitle;

  /// Data sources dialog and settings section title.
  ///
  /// In en, this message translates to:
  /// **'Data Sources'**
  String get dataSourcesTitle;

  /// Settings tile title for data sources.
  ///
  /// In en, this message translates to:
  /// **'Clinical & Wearable Data'**
  String get clinicalWearableDataTitle;

  /// Settings tile subtitle for clinical and wearable data.
  ///
  /// In en, this message translates to:
  /// **'eHospital patient database (institutional)'**
  String get clinicalWearableDataSubtitle;

  /// Settings tile title for AI response sources.
  ///
  /// In en, this message translates to:
  /// **'AI Health Responses'**
  String get aiHealthResponsesTitle;

  /// Settings tile subtitle for AI response sources.
  ///
  /// In en, this message translates to:
  /// **'Configured AI provider'**
  String get aiHealthResponsesSubtitle;

  /// Settings tile title for vital reference ranges.
  ///
  /// In en, this message translates to:
  /// **'Vitals Reference Ranges'**
  String get vitalsReferenceRangesTitle;

  /// Settings tile subtitle for vital reference ranges.
  ///
  /// In en, this message translates to:
  /// **'American Heart Association (AHA) guidelines'**
  String get vitalsReferenceRangesSubtitle;

  /// Settings section label for destructive actions.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZoneSection;

  /// Settings logout tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all data and return to login'**
  String get logoutSubtitle;

  /// Data source item title for clinical records.
  ///
  /// In en, this message translates to:
  /// **'Clinical Records & Risk Scores'**
  String get sourceClinicalTitle;

  /// Data source description for clinical records.
  ///
  /// In en, this message translates to:
  /// **'Sourced from the eHospital institutional patient database. Includes ECG results, diabetes analysis, heart disease risk, stroke prediction, lab tests, and diagnosis records provided by the connected hospital system.'**
  String get sourceClinicalDescription;

  /// Data source item title for wearable vitals.
  ///
  /// In en, this message translates to:
  /// **'Wearable Vitals'**
  String get sourceWearableTitle;

  /// Data source description for wearable vitals.
  ///
  /// In en, this message translates to:
  /// **'Heart rate, steps, calories, and sleep data sourced from Apple HealthKit via Apple Watch or other connected health devices.'**
  String get sourceWearableDescription;

  /// Data source item title for AI assistant.
  ///
  /// In en, this message translates to:
  /// **'AI Health Assistant'**
  String get sourceAssistantTitle;

  /// Data source description for AI assistant.
  ///
  /// In en, this message translates to:
  /// **'Responses generated by a local Llama model through Ollama. For informational purposes only - not a substitute for professional medical advice.'**
  String get sourceAssistantDescription;

  /// Data source item title for vitals reference ranges.
  ///
  /// In en, this message translates to:
  /// **'Vitals Reference Ranges'**
  String get sourceVitalsTitle;

  /// Data source description for vitals reference ranges.
  ///
  /// In en, this message translates to:
  /// **'Normal ranges for blood pressure, heart rate, and SpO2 are based on guidelines from the American Heart Association (AHA) and World Health Organization (WHO).'**
  String get sourceVitalsDescription;

  /// Data source item title for BMI classification.
  ///
  /// In en, this message translates to:
  /// **'BMI Classification'**
  String get sourceBmiTitle;

  /// Data source description for BMI classification.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index categories (Underweight, Normal, Overweight, Obese) follow the WHO BMI classification standard.'**
  String get sourceBmiDescription;

  /// Short medical disclaimer displayed in data sources.
  ///
  /// In en, this message translates to:
  /// **'This app is for informational purposes only and does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.'**
  String get medicalAdviceShortDisclaimer;

  /// Profile screen title.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileScreenTitle;

  /// Profile error when no patient id is stored.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get profileNotLoggedIn;

  /// Profile error when stored patient id cannot be parsed.
  ///
  /// In en, this message translates to:
  /// **'Invalid patient ID'**
  String get profileInvalidPatientId;

  /// Profile error when loading from eHospital fails.
  ///
  /// In en, this message translates to:
  /// **'Network error: {error}'**
  String profileNetworkError(String error);

  /// Profile empty state.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// Generic unknown fallback value.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// Profile field label for patient id.
  ///
  /// In en, this message translates to:
  /// **'Patient ID'**
  String get patientIdLabel;

  /// Profile field label for username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// Profile field label for email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Profile field label for role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// Profile field label for status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// Profile field label for creation date.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get memberSinceLabel;

  /// BMI calculator screen title.
  ///
  /// In en, this message translates to:
  /// **'BMI Calculator'**
  String get bmiCalculatorTitle;

  /// BMI validation error.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid height and weight'**
  String get validHeightWeightError;

  /// BMI height input label.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// BMI weight input label.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKgLabel;

  /// BMI calculate button.
  ///
  /// In en, this message translates to:
  /// **'Calculate BMI'**
  String get calculateBmiButton;

  /// BMI reference card title.
  ///
  /// In en, this message translates to:
  /// **'BMI Reference'**
  String get bmiReferenceTitle;

  /// BMI category.
  ///
  /// In en, this message translates to:
  /// **'Underweight'**
  String get bmiUnderweight;

  /// BMI category.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bmiNormal;

  /// BMI category.
  ///
  /// In en, this message translates to:
  /// **'Overweight'**
  String get bmiOverweight;

  /// BMI category.
  ///
  /// In en, this message translates to:
  /// **'Obese'**
  String get bmiObese;

  /// Medication tracker screen title.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsTitle;

  /// Medication bottom sheet title and button label.
  ///
  /// In en, this message translates to:
  /// **'Add Medication'**
  String get addMedicationTitle;

  /// Medication name input label.
  ///
  /// In en, this message translates to:
  /// **'Medication Name'**
  String get medicationNameLabel;

  /// Medication dosage input label.
  ///
  /// In en, this message translates to:
  /// **'Dosage (e.g. 10mg)'**
  String get dosageLabel;

  /// Medication frequency input label.
  ///
  /// In en, this message translates to:
  /// **'Frequency (e.g. Once daily)'**
  String get frequencyLabel;

  /// Medication time input label.
  ///
  /// In en, this message translates to:
  /// **'Time (e.g. 8:00 AM)'**
  String get timeLabel;

  /// Medication empty state title.
  ///
  /// In en, this message translates to:
  /// **'No medications yet'**
  String get noMedicationsYet;

  /// Medication empty state subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add one'**
  String get tapAddMedication;

  /// Medication card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{dosage} | {frequency} | {time}'**
  String medicationSummary(String dosage, String frequency, String time);

  /// Symptom logger screen title.
  ///
  /// In en, this message translates to:
  /// **'Symptom Log'**
  String get symptomLogTitle;

  /// Symptom bottom sheet title and button label.
  ///
  /// In en, this message translates to:
  /// **'Log Symptom'**
  String get logSymptomTitle;

  /// Symptom name input label.
  ///
  /// In en, this message translates to:
  /// **'Symptom Name'**
  String get symptomNameLabel;

  /// Symptom severity label.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get severityLabel;

  /// Symptom notes input label.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptionalLabel;

  /// Symptom empty state title.
  ///
  /// In en, this message translates to:
  /// **'No symptoms logged'**
  String get noSymptomsLogged;

  /// Symptom empty state subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to log one'**
  String get tapLogSymptom;

  /// Severity value 1.
  ///
  /// In en, this message translates to:
  /// **'Very Mild'**
  String get severityVeryMild;

  /// Severity value 2.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get severityMild;

  /// Severity value 3.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get severityModerate;

  /// Severity value 4.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get severitySevere;

  /// Severity value 5.
  ///
  /// In en, this message translates to:
  /// **'Very Severe'**
  String get severityVerySevere;

  /// Current severity in symptom bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'{severity} | {label}'**
  String severityValueLabel(int severity, String label);

  /// Severity badge in symptom card.
  ///
  /// In en, this message translates to:
  /// **'{label} ({severity}/5)'**
  String severityBadgeLabel(String label, int severity);

  /// Generic save button label.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Placeholder shown when editable emergency information has not been set.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get tapToSet;

  /// Health goals screen title.
  ///
  /// In en, this message translates to:
  /// **'Health Goals'**
  String get healthGoalsTitle;

  /// Daily steps goal card title.
  ///
  /// In en, this message translates to:
  /// **'Daily Steps'**
  String get dailyStepsTitle;

  /// Sleep goal card title.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleepTitle;

  /// Calories burned goal card title.
  ///
  /// In en, this message translates to:
  /// **'Calories Burned'**
  String get caloriesBurnedTitle;

  /// Short title used when editing the steps goal.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsGoalTitle;

  /// Short title used when editing the calories goal.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesGoalTitle;

  /// Steps unit label.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get stepsUnit;

  /// Long hours unit label.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hoursUnit;

  /// Short hours unit label.
  ///
  /// In en, this message translates to:
  /// **'hrs'**
  String get hrsUnit;

  /// Kilocalorie unit label.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// Health goals tab label for goal progress.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get healthGoalsGoalsTab;

  /// Health goals tab label for training records.
  ///
  /// In en, this message translates to:
  /// **'Training Records'**
  String get healthGoalsTrainingRecordsTab;

  /// Training records section title.
  ///
  /// In en, this message translates to:
  /// **'Training Records'**
  String get trainingRecordsTitle;

  /// Tooltip for refreshing remote training records.
  ///
  /// In en, this message translates to:
  /// **'Refresh training records'**
  String get trainingRecordsRefreshTooltip;

  /// Tooltip for syncing workouts from Apple Health or Google Health.
  ///
  /// In en, this message translates to:
  /// **'Sync platform workouts'**
  String get trainingRecordsSyncTooltip;

  /// Loading text for training records.
  ///
  /// In en, this message translates to:
  /// **'Loading training records...'**
  String get trainingRecordsLoading;

  /// Empty state text for training records.
  ///
  /// In en, this message translates to:
  /// **'No synced training records available.'**
  String get trainingRecordsEmpty;

  /// Generic error text for training records.
  ///
  /// In en, this message translates to:
  /// **'Could not load training records.'**
  String get trainingRecordsError;

  /// Metric label for training record source provider.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get trainingRecordsSourceLabel;

  /// Metric label for training record duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get trainingRecordsDurationLabel;

  /// Metric label for training record distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get trainingRecordsDistanceLabel;

  /// Metric label for training record energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get trainingRecordsEnergyLabel;

  /// Metric label for training record steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get trainingRecordsStepsLabel;

  /// Fallback date label for a training record with no timestamp.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get trainingRecordsUnknownDate;

  /// Status text shown after platform workout sync succeeds.
  ///
  /// In en, this message translates to:
  /// **'Workout sync complete.'**
  String get trainingRecordsSyncSuccess;

  /// Tooltip for editing a goal.
  ///
  /// In en, this message translates to:
  /// **'Edit goal'**
  String get editGoalTooltip;

  /// Dialog title for editing a health goal.
  ///
  /// In en, this message translates to:
  /// **'Edit {title} Goal'**
  String editGoalTitle(String title);

  /// Integer metric value with unit.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String metricValueInt(int value, String unit);

  /// Decimal metric value with unit.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}'**
  String metricValueDecimal(double value, String unit);

  /// Goal card progress text.
  ///
  /// In en, this message translates to:
  /// **'{actual} / {goal} {unit}'**
  String goalProgressValue(String actual, String goal, String unit);

  /// Emergency SOS screen title.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySosTitle;

  /// Warning banner copy on the Emergency SOS screen.
  ///
  /// In en, this message translates to:
  /// **'Keep this information up to date. It could save your life in an emergency.'**
  String get emergencyUpdateWarning;

  /// Emergency SOS medical information section title.
  ///
  /// In en, this message translates to:
  /// **'Medical Information'**
  String get medicalInformationTitle;

  /// Emergency SOS contact section title.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContactTitle;

  /// Emergency field label for blood type.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodTypeLabel;

  /// Emergency field label for allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesLabel;

  /// Emergency field label for contact name.
  ///
  /// In en, this message translates to:
  /// **'Contact Name'**
  String get contactNameLabel;

  /// Emergency field label for contact phone.
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get contactPhoneLabel;

  /// Dialog title for editing an emergency information field.
  ///
  /// In en, this message translates to:
  /// **'Edit {title}'**
  String editFieldTitle(String title);

  /// Emergency call button label.
  ///
  /// In en, this message translates to:
  /// **'CALL EMERGENCY (911)'**
  String get callEmergencyButton;

  /// Snackbar shown when the emergency phone dialer cannot be opened.
  ///
  /// In en, this message translates to:
  /// **'Cannot launch phone dialer'**
  String get cannotLaunchPhoneDialer;

  /// Dashboard greeting for a signed-in patient.
  ///
  /// In en, this message translates to:
  /// **'Hello, {username}!'**
  String dashboardHelloUser(String username);

  /// Dashboard fallback greeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get dashboardWelcome;

  /// Dashboard helper text under the greeting.
  ///
  /// In en, this message translates to:
  /// **'What would you like to check today?'**
  String get dashboardPrompt;

  /// Dashboard section title for monitoring features.
  ///
  /// In en, this message translates to:
  /// **'Health Monitoring'**
  String get healthMonitoringSection;

  /// Dashboard section title for management features.
  ///
  /// In en, this message translates to:
  /// **'Health Management'**
  String get healthManagementSection;

  /// Dashboard card title for wearable vitals.
  ///
  /// In en, this message translates to:
  /// **'Wearable Vitals'**
  String get wearableVitalsTitle;

  /// Dashboard card subtitle for wearable vitals.
  ///
  /// In en, this message translates to:
  /// **'Steps | Calories | HR'**
  String get wearableVitalsSubtitle;

  /// Dashboard card title for vitals history.
  ///
  /// In en, this message translates to:
  /// **'Vitals History'**
  String get vitalsHistoryTitle;

  /// Dashboard card subtitle for vitals history.
  ///
  /// In en, this message translates to:
  /// **'Clinical records'**
  String get vitalsHistorySubtitle;

  /// Dashboard card title for health insights.
  ///
  /// In en, this message translates to:
  /// **'Health Insights'**
  String get healthInsightsTitle;

  /// Dashboard card subtitle for health insights.
  ///
  /// In en, this message translates to:
  /// **'Risk analysis & alerts'**
  String get healthInsightsSubtitle;

  /// Dashboard card title for trend analysis.
  ///
  /// In en, this message translates to:
  /// **'Trend Analysis'**
  String get trendAnalysisTitle;

  /// Dashboard card subtitle for trend analysis.
  ///
  /// In en, this message translates to:
  /// **'This week vs last'**
  String get trendAnalysisSubtitle;

  /// Dashboard card subtitle for medications.
  ///
  /// In en, this message translates to:
  /// **'Track & manage meds'**
  String get medicationsSubtitle;

  /// Dashboard card subtitle for symptom log.
  ///
  /// In en, this message translates to:
  /// **'Daily symptom diary'**
  String get symptomLogSubtitle;

  /// Dashboard card subtitle for health goals.
  ///
  /// In en, this message translates to:
  /// **'Steps | Sleep | Calories'**
  String get healthGoalsSubtitle;

  /// Dashboard card subtitle for BMI calculator.
  ///
  /// In en, this message translates to:
  /// **'Check your BMI'**
  String get bmiCalculatorSubtitle;

  /// Dashboard featured card title for AI assistant.
  ///
  /// In en, this message translates to:
  /// **'AI Health Assistant'**
  String get aiHealthAssistantTitle;

  /// Dashboard featured card subtitle for AI assistant.
  ///
  /// In en, this message translates to:
  /// **'Ask AI about your health data'**
  String get aiHealthAssistantSubtitle;

  /// Title for the AI assistant module picker.
  ///
  /// In en, this message translates to:
  /// **'Choose an AI tool'**
  String get assistantPickerTitle;

  /// Primary action for opening the selected AI assistant module.
  ///
  /// In en, this message translates to:
  /// **'Open {moduleName}'**
  String assistantPickerOpenAction(String moduleName);

  /// Label for the health chat AI module.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get assistantModuleChatLabel;

  /// Description for the health chat AI module.
  ///
  /// In en, this message translates to:
  /// **'Ask questions about your health data and wellness trends.'**
  String get assistantModuleChatDescription;

  /// Label for the report analysis AI module.
  ///
  /// In en, this message translates to:
  /// **'Report Analyze'**
  String get assistantModuleReportLabel;

  /// Description for the report analysis AI module.
  ///
  /// In en, this message translates to:
  /// **'Upload lab work, reports, images, or PDFs for plain-language analysis.'**
  String get assistantModuleReportDescription;

  /// Label for the nutrition monitoring AI module.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Monitor'**
  String get assistantModuleNutritionLabel;

  /// Description for the nutrition monitoring AI module.
  ///
  /// In en, this message translates to:
  /// **'Analyze meal images, check EHR-aware nutrition risks, and track goals.'**
  String get assistantModuleNutritionDescription;

  /// Tooltip for clearing AI assistant chat history.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get clearChatTooltip;

  /// Tooltip for starting a new health assistant chat session.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get newChatTooltip;

  /// Tooltip for opening health assistant chat history.
  ///
  /// In en, this message translates to:
  /// **'Chat history'**
  String get assistantHistoryTooltip;

  /// Empty state shown when no health assistant chat history exists.
  ///
  /// In en, this message translates to:
  /// **'No saved chats yet'**
  String get assistantNoHistory;

  /// Health assistant banner title.
  ///
  /// In en, this message translates to:
  /// **'AI Wellness Assistant'**
  String get aiWellnessAssistantTitle;

  /// Short disclaimer shown in the health assistant banner.
  ///
  /// In en, this message translates to:
  /// **'General wellness info only | Not medical advice'**
  String get aiWellnessAssistantDisclaimer;

  /// Health assistant empty chat title.
  ///
  /// In en, this message translates to:
  /// **'Ask about your wellness data'**
  String get assistantEmptyTitle;

  /// Example health assistant prompt about heart rate.
  ///
  /// In en, this message translates to:
  /// **'\"What does my heart rate trend mean?\"'**
  String get assistantPromptHeartRate;

  /// Example health assistant prompt about activity.
  ///
  /// In en, this message translates to:
  /// **'\"How can I improve my activity levels?\"'**
  String get assistantPromptActivity;

  /// Health assistant empty state disclaimer.
  ///
  /// In en, this message translates to:
  /// **'For general wellness info only.\nNot a substitute for medical advice.'**
  String get assistantGeneralDisclaimer;

  /// Health assistant chat input placeholder.
  ///
  /// In en, this message translates to:
  /// **'Ask about your health...'**
  String get assistantInputHint;

  /// Assistant response when no patient id is available.
  ///
  /// In en, this message translates to:
  /// **'Please log in before using the health assistant.'**
  String get assistantLoginRequired;

  /// Assistant response when AI generation fails.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String assistantErrorMessage(String error);

  /// Assistant typing indicator label.
  ///
  /// In en, this message translates to:
  /// **'Thinking...'**
  String get assistantThinking;

  /// Device connection screen title.
  ///
  /// In en, this message translates to:
  /// **'Device Manager'**
  String get deviceManagerTitle;

  /// Device screen info banner title.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch -> eHospital'**
  String get deviceInfoTitle;

  /// Device screen info banner body.
  ///
  /// In en, this message translates to:
  /// **'On a real device: patient logs in and taps \"Sync Apple Watch\" to push live Health data.\nFor demo/testing: tap Simulate to generate 7 days of realistic wearable data for any patient.'**
  String get deviceInfoBody;

  /// Device screen patient count section label.
  ///
  /// In en, this message translates to:
  /// **'{count} Patients in eHospital DB'**
  String patientsInDb(int count);

  /// Fallback patient name when username is missing.
  ///
  /// In en, this message translates to:
  /// **'Patient {id}'**
  String patientFallbackName(String id);

  /// Device status chip when wearable data exists.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get connectedStatus;

  /// Device status chip when no wearable data exists.
  ///
  /// In en, this message translates to:
  /// **'NO DATA'**
  String get noDataStatus;

  /// Patient card metadata line.
  ///
  /// In en, this message translates to:
  /// **'ID: {patientId}  |  {email}'**
  String patientDeviceMeta(String patientId, String email);

  /// Device last sync fallback.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// Wearable records count label.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// Device simulation button label.
  ///
  /// In en, this message translates to:
  /// **'Simulate'**
  String get simulateButton;

  /// Relative time label for immediate sync.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// Relative time label in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// Relative time label in hours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// Relative time label in days.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// Device simulation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Simulating Data'**
  String get simulatingDataTitle;

  /// Simulation dialog patient label.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name}'**
  String patientNameLabel(String name);

  /// Simulation dialog data pipeline label.
  ///
  /// In en, this message translates to:
  /// **'Apple Watch  -> Apple Health  -> eHospital DB'**
  String get appleHealthPipeline;

  /// Simulation dialog completion message.
  ///
  /// In en, this message translates to:
  /// **'{total} days uploaded to eHospital.'**
  String uploadCompleteMessage(int total);

  /// Simulation dialog upload progress message.
  ///
  /// In en, this message translates to:
  /// **'Uploading day {progress} of {total}...'**
  String uploadingDayMessage(int progress, int total);

  /// Trend comparison legend label for last week.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeekLabel;

  /// Trend comparison legend label for this week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeekLabel;

  /// Trend analysis disclaimer banner text.
  ///
  /// In en, this message translates to:
  /// **'For informational purposes only. Not a medical device. Always consult a qualified healthcare professional before making any medical decisions.'**
  String get trendDisclaimer;

  /// Trend metric title for steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsTitle;

  /// Trend metric description for steps.
  ///
  /// In en, this message translates to:
  /// **'Average daily steps this week vs last week. Goal: 10,000 steps/day.'**
  String get stepsTrendDescription;

  /// Trend metric title for active calories.
  ///
  /// In en, this message translates to:
  /// **'Active Calories'**
  String get activeCaloriesTitle;

  /// Trend metric description for active calories.
  ///
  /// In en, this message translates to:
  /// **'Average calories burned per day. Healthy range: 300-600 kcal/day.'**
  String get activeCaloriesTrendDescription;

  /// Trend metric title for heart rate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRateTitle;

  /// Trend metric description for heart rate.
  ///
  /// In en, this message translates to:
  /// **'Average resting heart rate. Normal range: 60-100 bpm.'**
  String get heartRateTrendDescription;

  /// Trend metric description for sleep.
  ///
  /// In en, this message translates to:
  /// **'Average hours of sleep per night. Recommended: 7-9 hrs/night.'**
  String get sleepTrendDescription;

  /// Beats per minute unit label.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get bpmUnit;

  /// Trend metric status when current week has no data.
  ///
  /// In en, this message translates to:
  /// **'No data this week'**
  String get noDataThisWeek;

  /// Trend metric status below normal range.
  ///
  /// In en, this message translates to:
  /// **'Below normal range'**
  String get belowNormalRange;

  /// Trend metric status above normal range.
  ///
  /// In en, this message translates to:
  /// **'Above normal range'**
  String get aboveNormalRange;

  /// Trend metric status within normal range.
  ///
  /// In en, this message translates to:
  /// **'Within normal range'**
  String get withinNormalRange;

  /// Trend chart bottom axis label with period and metric value.
  ///
  /// In en, this message translates to:
  /// **'{period}\n{value} {unit}'**
  String trendChartAxisLabel(String period, String value, String unit);

  /// AI insight label shown in trend cards.
  ///
  /// In en, this message translates to:
  /// **'AI Insight'**
  String get aiInsightLabel;

  /// AI insight loading label.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generatingInsight;

  /// AI insight empty state for trend cards.
  ///
  /// In en, this message translates to:
  /// **'Sync data to generate insight.'**
  String get syncDataToGenerateInsight;

  /// Vitals history summary banner title.
  ///
  /// In en, this message translates to:
  /// **'Clinical Vitals History'**
  String get clinicalVitalsHistoryTitle;

  /// Record count summary.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{record} other{records}} found'**
  String recordsFound(int count);

  /// Vitals history empty state.
  ///
  /// In en, this message translates to:
  /// **'No vitals history found'**
  String get noVitalsHistoryFound;

  /// Vitals history related records section title.
  ///
  /// In en, this message translates to:
  /// **'Related Records'**
  String get relatedRecordsTitle;

  /// Vitals history disclaimer banner text.
  ///
  /// In en, this message translates to:
  /// **'For informational & wellness purposes only. Not a medical device. Does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.'**
  String get historyDisclaimer;

  /// Generic data card empty state.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// Additional hidden record count label.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more records'**
  String moreRecords(int count);

  /// Related records card title for lab tests.
  ///
  /// In en, this message translates to:
  /// **'Lab Tests'**
  String get labTestsTitle;

  /// Related records card title for ECG.
  ///
  /// In en, this message translates to:
  /// **'ECG'**
  String get ecgTitle;

  /// Related records card title for glucose wellness.
  ///
  /// In en, this message translates to:
  /// **'Glucose Wellness'**
  String get glucoseWellnessTitle;

  /// Related records card title for heart disease indicators.
  ///
  /// In en, this message translates to:
  /// **'Heart Health Indicators'**
  String get heartHealthIndicatorsTitle;

  /// Related records card title for stroke risk indicators.
  ///
  /// In en, this message translates to:
  /// **'Stroke Risk Indicators'**
  String get strokeRiskIndicatorsTitle;

  /// Related records card title for diagnosis records.
  ///
  /// In en, this message translates to:
  /// **'Clinical Records'**
  String get clinicalRecordsTitle;

  /// Vitals screen title.
  ///
  /// In en, this message translates to:
  /// **'Vital Signs'**
  String get vitalSignsTitle;

  /// Vitals sync loading banner text.
  ///
  /// In en, this message translates to:
  /// **'Syncing from Apple Watch...'**
  String get syncingAppleWatch;

  /// Vitals warning banner shown for suspicious wearable sync data.
  ///
  /// In en, this message translates to:
  /// **'Data sync issue: Heart rate recorded as 0 BPM. Wearable may not be syncing correctly.'**
  String get vitalsSyncIssue;

  /// Tooltip for opening the device manager from the vitals screen.
  ///
  /// In en, this message translates to:
  /// **'Device Manager'**
  String get deviceManagerTooltip;

  /// Tooltip for syncing Apple Watch data.
  ///
  /// In en, this message translates to:
  /// **'Sync from Apple Watch'**
  String get syncFromAppleWatchTooltip;

  /// Tooltip for opening the manual vitals sheet.
  ///
  /// In en, this message translates to:
  /// **'Log Vitals manually'**
  String get logVitalsManuallyTooltip;

  /// Short loading label while syncing wearable data.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncingShort;

  /// Floating action button label for Apple Watch sync.
  ///
  /// In en, this message translates to:
  /// **'Sync Apple Watch'**
  String get syncAppleWatchButton;

  /// Manual vitals bottom sheet title.
  ///
  /// In en, this message translates to:
  /// **'Log Vitals to eHospital'**
  String get logVitalsTitle;

  /// Manual vitals sheet endpoint helper label.
  ///
  /// In en, this message translates to:
  /// **'POST -> /table/wearable_vitals'**
  String get wearableVitalsEndpointLabel;

  /// Manual vitals field label for heart rate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate (bpm)'**
  String get heartRateBpmLabel;

  /// Manual vitals field label for steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get stepsInputLabel;

  /// Manual vitals field label for calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesInputLabel;

  /// Manual vitals field label for sleep hours.
  ///
  /// In en, this message translates to:
  /// **'Sleep (hrs)'**
  String get sleepHoursInputLabel;

  /// Button label while sending manual vitals.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingButton;

  /// Button label for sending manual vitals to eHospital.
  ///
  /// In en, this message translates to:
  /// **'Send to eHospital'**
  String get sendToEHospitalButton;

  /// Validation snackbar when all manual vitals fields are empty.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one value'**
  String get enterAtLeastOneValue;

  /// Snackbar after manual vitals are saved.
  ///
  /// In en, this message translates to:
  /// **'Vitals saved to eHospital DB'**
  String get vitalsSavedMessage;

  /// Vitals clinical reference card title.
  ///
  /// In en, this message translates to:
  /// **'Clinical Reference'**
  String get clinicalReferenceTitle;

  /// Short eHospital source label.
  ///
  /// In en, this message translates to:
  /// **'eHospital'**
  String get eHospitalSourceLabel;

  /// Short ECG label.
  ///
  /// In en, this message translates to:
  /// **'ECG'**
  String get ecgShortLabel;

  /// Blood pressure metric label.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressureLabel;

  /// Metric chart normal range label.
  ///
  /// In en, this message translates to:
  /// **'Normal range'**
  String get normalRangeLabel;

  /// Metric chart latest statistic label.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latestMetricLabel;

  /// Metric chart average statistic label.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get averageMetricLabel;

  /// Metric chart minimum statistic label.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minMetricLabel;

  /// Metric chart maximum statistic label.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxMetricLabel;

  /// Metric status when no value is available.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get noDataStatusLabel;

  /// Metric status below normal range.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowStatusLabel;

  /// Metric status above normal range.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highStatusLabel;

  /// Metric status within normal range.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normalStatusLabel;

  /// Vitals chart description for steps.
  ///
  /// In en, this message translates to:
  /// **'Steps walked today. A healthy goal is 10,000 steps per day.'**
  String get stepsMetricDescription;

  /// Vitals chart description for calories.
  ///
  /// In en, this message translates to:
  /// **'Active calories burned. Healthy range: 300-800 kcal/day.'**
  String get caloriesMetricDescription;

  /// Vitals chart description for heart rate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate in beats per minute. Normal resting: 60-100 bpm.'**
  String get heartRateMetricDescription;

  /// Vitals chart description for sleep.
  ///
  /// In en, this message translates to:
  /// **'Hours of sleep recorded. Recommended: 7-9 hours per night.'**
  String get sleepMetricDescription;

  /// Vitals chart note for the clinical heart-rate baseline.
  ///
  /// In en, this message translates to:
  /// **'Green dashed line = clinical baseline HR from hospital records.'**
  String get clinicalBaselineNote;

  /// Vitals chart note for missing wearable sleep data.
  ///
  /// In en, this message translates to:
  /// **'0 hrs means the wearable did not record sleep for that period.'**
  String get wearableSleepMissingNote;

  /// Generic refresh tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Insights header title.
  ///
  /// In en, this message translates to:
  /// **'Unified Health Analysis'**
  String get unifiedHealthAnalysisTitle;

  /// Insights header subtitle.
  ///
  /// In en, this message translates to:
  /// **'Wearable + clinical data - timestamp merged'**
  String get unifiedHealthAnalysisSubtitle;

  /// Insights merged record count badge.
  ///
  /// In en, this message translates to:
  /// **'{count} wearable-clinical record pairs merged (+/-48h window)'**
  String mergedRecordPairs(int count);

  /// Insights count heading.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{Insight} other{Insights}} Found'**
  String insightsFound(int count);

  /// Final medical disclaimer footer on the insights screen.
  ///
  /// In en, this message translates to:
  /// **'IMPORTANT: This app is for informational and wellness purposes only. It is not a medical device and does not provide medical advice, diagnosis, or treatment. All wellness indicators and risk scores are for general awareness only. Always consult a qualified healthcare professional before making any health-related decisions.'**
  String get insightsMedicalFooter;

  /// Short disclaimer banner on insights and history screens.
  ///
  /// In en, this message translates to:
  /// **'For informational & wellness purposes only. Not a medical device. Does not provide medical advice, diagnosis, or treatment. Always consult a qualified healthcare professional.'**
  String get insightsDisclaimer;

  /// Insights clinical summary section title.
  ///
  /// In en, this message translates to:
  /// **'Patient Clinical Summary'**
  String get clinicalSummaryTitle;

  /// Insights clinical summary subsection title.
  ///
  /// In en, this message translates to:
  /// **'Clinical Vitals (Most Recent)'**
  String get clinicalVitalsMostRecent;

  /// Insights wearable summary subsection title.
  ///
  /// In en, this message translates to:
  /// **'Wearable Activity (Most Recent)'**
  String get wearableActivityMostRecent;

  /// Dynamic note label.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String noteLabel(String note);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
