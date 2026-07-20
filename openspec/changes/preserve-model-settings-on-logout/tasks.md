## 1. Session Persistence Audit

- [ ] 1.1 Identify all SharedPreferences keys currently written during login and Settings logout-related flows.
- [ ] 1.2 Confirm the model invocation settings key is owned by `ModelInvocationSettingsStore` and should not be removed by account logout.

## 2. Logout Implementation

- [ ] 2.1 Replace `SharedPreferences.clear()` in the Settings logout flow with targeted removal of active patient session keys.
- [ ] 2.2 Keep the existing logout confirmation dialog and `Navigator.pushNamedAndRemoveUntil(context, '/', ...)` route reset behavior.
- [ ] 2.3 Preserve explicit model invocation reset behavior through `ModelInvocationSettingsStore.clear()`.

## 3. Tests

- [ ] 3.1 Add or update Flutter tests that seed a saved model invocation profile, perform session clearing/logout logic, and verify the profile remains saved.
- [ ] 3.2 Add or update Flutter tests that verify patient session keys are removed by logout.
- [ ] 3.3 Verify explicit model invocation clearing still removes the saved profile.

## 4. Verification

- [ ] 4.1 Run the relevant Flutter test suite for settings/auth/model invocation persistence.
- [ ] 4.2 Manually verify the app returns to login after logout and the model invocation settings page still shows the previous configuration after signing in again.
