# UI Style Checklist

- [x] Urgent-care code lives under `src/app/lib/features/urgent_care`.
- [x] The host `SmartHealthApp` remains the only Flutter app shell.
- [x] The urgent-care route is registered as a patient-facing mobile route.
- [x] The dashboard entry opens `/urgent-care`, not a staff/admin dashboard.
- [x] Screens use DTI6302 `AppSliverHeader`, `AppCard`, `AppSpacing`, `AppColors`, and Material 3 controls.
- [x] Patient workflows use mobile form controls, segmented tabs, status cards, refresh button, and feedback form.
- [x] Staff queue dashboard screens, staff action controls, completed staff history, and staff alert review screens are absent.
- [x] `patient_app/lib/main.dart` is not copied as the host app entry point.
- [x] `flutter_frontend/lib/main.dart` is not copied or rebuilt as a mobile route.
- [x] No generated native Android/iOS project artifacts from CareFlow are copied into `src/app`.
