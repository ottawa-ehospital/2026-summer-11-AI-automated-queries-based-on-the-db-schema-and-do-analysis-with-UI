## 1. Inventory and Baseline

- [x] 1.1 Run a targeted mojibake scan across migrated Flutter feature files.
- [x] 1.2 Run `flutter analyze` and capture current warnings/errors relevant to legacy cleanup.
- [x] 1.3 Identify touched legacy files that contain corrupted comments, corrupted visible strings, unused locals, unused private helpers, or stale parsing logic.

## 2. Source Text Hygiene

- [x] 2.1 Remove decorative mojibake comment separators from migrated feature files.
- [x] 2.2 Replace useful corrupted comments with concise readable comments.
- [x] 2.3 Repair visible UI/debug text only where the text is clearly corrupted or misleading.
- [x] 2.4 Ensure cleaned Dart files are saved as UTF-8 and analyzable.
- [x] 2.5 Add concise comments around non-obvious Flutter API client, repository, and service boundaries.
- [x] 2.6 Add concise comments around non-obvious backend router, client, service, and compatibility shim boundaries.
- [x] 2.7 Add or document a repeatable `rg` text hygiene scan command for known mojibake markers.

## 3. Legacy Function Reliability

- [x] 3.1 Remove or repair unused local variables in touched legacy functions.
- [x] 3.2 Remove or repair unused private helper methods that are legacy leftovers.
- [x] 3.3 Fix helper functions that still assume pre-repository URL/JSON parsing responsibilities.
- [x] 3.4 Confirm route widgets and feature barrel exports still resolve through `main.dart`.
- [x] 3.5 Keep backend API contracts, repository method signatures, and eHospital table contracts unchanged.
- [x] 3.6 Review added API comments to ensure they describe existing contracts rather than inventing new behavior.

## 4. Verification

- [x] 4.1 Run the mojibake/text hygiene scan and confirm no targeted corrupted markers remain in cleaned files.
- [x] 4.2 Run `flutter analyze` and confirm no encoding, URI, compile, or newly introduced legacy-function errors remain.
- [x] 4.3 Run `flutter test`.
- [x] 4.4 Build Flutter web with backend provider defines.
- [x] 4.5 Run OpenSpec apply status and confirm task progress is accurate.
