import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

// Presentation-only lookup boundary. New user-facing strings should be added
// to ARB files and consumed through AppLocalizations, not hardcoded in screens.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
