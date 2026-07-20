## Context

Flutter login stores the selected eHospital user in `SharedPreferences` using session keys such as `patient_id`, `patient_email`, and `patient_username`. The Settings logout flow currently calls `SharedPreferences.clear()`, which removes those session keys but also deletes unrelated local preferences, including the non-secret `model_invocation_settings` profile managed by `ModelInvocationSettingsStore`.

The model invocation profile is a developer/tester preference, not an account credential. It already has its own store and explicit clear behavior, so logout should not remove it as a side effect.

## Goals / Non-Goals

**Goals:**

- Clear the current patient session when the user confirms logout.
- Preserve saved model invocation settings across logout and the return to the login route.
- Keep the logout confirmation UI and route reset behavior unchanged.
- Cover the persistence boundary with focused Flutter tests.

**Non-Goals:**

- Changing backend authentication or authorization behavior.
- Adding cloud/account sync for model invocation settings.
- Preserving every local preference forever; this change only guarantees model invocation settings survive logout.
- Redesigning the Settings UI.

## Decisions

1. Replace blanket preference clearing with targeted session clearing.

   Logout should remove known account/session keys instead of calling `prefs.clear()`. This protects unrelated local configuration and makes the behavior easier to reason about. The alternative was to snapshot model invocation settings before `clear()` and restore them afterward, but that keeps the broad destructive operation and risks deleting future non-session preferences.

2. Keep model invocation persistence owned by `ModelInvocationSettingsStore`.

   The settings store already owns the `model_invocation_settings` key and provides explicit `save`, `loadSaved`, `loadEffective`, and `clear` methods. Logout should avoid reaching into that store except through tests that verify the saved value remains available. The alternative was to add special-case preservation logic in SettingsScreen, but that would couple logout to the model settings storage format.

3. Prefer a small session-facing helper if implementation needs reuse.

   If only Settings uses logout, the targeted removal can stay close to the existing flow. If tests or future flows need a shared boundary, add an `AuthRepository.logout()` or local session clear method that removes only session keys. This keeps account state ownership out of widget code without introducing a larger auth framework.

## Risks / Trade-offs

- Unknown session-related preferences could remain after logout -> Audit current SharedPreferences keys and remove known patient/account keys; add new keys to the session clear helper when introduced.
- Some per-patient preferences, such as notification toggles keyed by patient id, may remain locally -> Accept for this change unless they expose sensitive account data; the requested guarantee is preserving model invocation settings while ending the active session.
- Tests using SharedPreferences mocks can miss route behavior -> Cover persistence with unit/widget-level tests and rely on existing navigation behavior unless implementation changes it.
